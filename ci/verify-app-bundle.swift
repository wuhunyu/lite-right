import Foundation

/// Inspect real Xcode products, including the embedded Finder Sync extension.
/// This is a build artifact test, not a claim that Finder registered the extension.
enum BundleCheckError: Error, CustomStringConvertible {
    case invalid(String)
    var description: String {
        switch self { case .invalid(let message): return message }
    }
}

func require(_ condition: @autoclosure () -> Bool, _ message: String) throws {
    guard condition() else { throw BundleCheckError.invalid(message) }
    print("PASS: \(message)")
}

func infoDictionary(at bundle: URL) throws -> [String: Any] {
    let path = bundle.appendingPathComponent("Contents/Info.plist")
    let data = try Data(contentsOf: path)
    guard let dictionary = try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] else {
        throw BundleCheckError.invalid("Malformed Info.plist: \(path.path)")
    }
    return dictionary
}

func check() throws {
    guard CommandLine.arguments.count == 2 else {
        throw BundleCheckError.invalid("Usage: swift ci/verify-app-bundle.swift /path/to/LiteRight.app")
    }
    let app = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
    let finder = app.appendingPathComponent("Contents/PlugIns/LiteRightFinderExtension.appex", isDirectory: true)
    let appInfo = try infoDictionary(at: app)
    let extInfo = try infoDictionary(at: finder)
    let finderManifest = extInfo["NSExtension"] as? [String: Any]
    let urlEntries = appInfo["CFBundleURLTypes"] as? [[String: Any]] ?? []
    let hasScheme = urlEntries.contains { (($0["CFBundleURLSchemes"] as? [String]) ?? []).contains("lite-right") }

    try require(appInfo["CFBundleIdentifier"] as? String == "com.wuhunyu.literight", "Main app bundle ID")
    try require(FileManager.default.isExecutableFile(atPath: app.appendingPathComponent("Contents/MacOS/LiteRight").path), "Main app contains executable")
    try require(appInfo["LSUIElement"] as? Bool == true, "Menu-bar/accessory activation is configured")
    try require(hasScheme, "lite-right:// URL scheme is registered")
    try require(finder.pathExtension == "appex", "Embedded Finder extension exists")
    try require(extInfo["CFBundleIdentifier"] as? String == "com.wuhunyu.literight.finder", "Finder extension bundle ID")
    try require(FileManager.default.isExecutableFile(atPath: finder.appendingPathComponent("Contents/MacOS/LiteRightFinderExtension").path), "Finder extension contains executable")
    try require(finderManifest?["NSExtensionPointIdentifier"] as? String == "com.apple.FinderSync", "Finder Sync extension point")
    let principal = finderManifest?["NSExtensionPrincipalClass"] as? String ?? ""
    try require(principal.contains("FinderSync") && !principal.contains("$("), "Finder Sync principal class expanded")
    try require(FileManager.default.fileExists(atPath: app.appendingPathComponent("Contents/Resources/Assets.car").path), "App icon assets compiled")
    print("Bundle structure checks passed. Runtime registration and privacy consent remain unverified.")
}

do {
    try check()
} catch {
    fputs("FAIL: \(error)\n", stderr)
    exit(1)
}
