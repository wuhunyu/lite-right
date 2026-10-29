import Foundation

/// Validates an actually signed, installed LiteRight.app on macOS.
/// This tool is deliberately separate from unsigned GitHub Actions bundle checks.
enum SignatureVerificationError: Error, CustomStringConvertible {
    case invalid(String)
    var description: String {
        switch self { case let .invalid(text): text }
    }
}

func require(_ condition: @autoclosure () -> Bool, _ message: String) throws {
    guard condition() else { throw SignatureVerificationError.invalid(message) }
    print("PASS: \(message)")
}

@discardableResult
func execute(_ executable: String, _ args: [String]) throws -> String {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: executable)
    process.arguments = args
    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = pipe
    try process.run()
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    process.waitUntilExit()
    let text = String(data: data, encoding: .utf8) ?? ""
    guard process.terminationStatus == 0 else {
        throw SignatureVerificationError.invalid("\(executable) \(args.joined(separator: " ")) failed (\(process.terminationStatus)): \(text)")
    }
    return text
}

func info(at bundle: URL) throws -> [String: Any] {
    let data = try Data(contentsOf: bundle.appendingPathComponent("Contents/Info.plist"))
    guard let info = try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] else {
        throw SignatureVerificationError.invalid("Invalid Info.plist: \(bundle.path)")
    }
    return info
}

func signingTeam(at bundle: URL) throws -> String {
    let output = try execute("/usr/bin/codesign", ["-d", "--verbose=4", "--", bundle.path])
    guard let line = output.split(separator: "\n").first(where: { $0.hasPrefix("TeamIdentifier=") }) else {
        throw SignatureVerificationError.invalid("No TeamIdentifier: \(bundle.path)")
    }
    let team = String(line.dropFirst("TeamIdentifier=".count))
    guard !team.isEmpty, team != "not set" else {
        throw SignatureVerificationError.invalid("Missing Apple Developer Team signing: \(bundle.path)")
    }
    return team
}

func entitlementGroups(at bundle: URL) throws -> Set<String> {
    let output = try execute("/usr/bin/codesign", ["-d", "--entitlements", ":-", "--", bundle.path])
    guard let start = output.range(of: "<plist"), let end = output.range(of: "</plist>") else {
        throw SignatureVerificationError.invalid("Missing XML entitlements: \(bundle.path). Check code signing.")
    }
    let xml = String(output[start.lowerBound..<end.upperBound])
    guard let data = xml.data(using: .utf8),
          let plist = try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
          let groups = plist["com.apple.security.application-groups"] as? [String] else {
        throw SignatureVerificationError.invalid("Missing App Group entitlement: \(bundle.path)")
    }
    return Set(groups)
}

func main() throws {
    guard CommandLine.arguments.count == 2 else {
        throw SignatureVerificationError.invalid("Usage: swift ci/verify-signed-app.swift /Applications/LiteRight.app")
    }
    let app = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
    let finder = app.appendingPathComponent("Contents/PlugIns/LiteRightFinderExtension.appex", isDirectory: true)
    try require(FileManager.default.fileExists(atPath: finder.path), "Finder extension is embedded")
    let appInfo = try info(at: app)
    let finderInfo = try info(at: finder)
    try require(appInfo["CFBundleIdentifier"] as? String == "com.wuhunyu.literight", "App identifier")
    try require(finderInfo["CFBundleIdentifier"] as? String == "com.wuhunyu.literight.finder", "Extension identifier")
    _ = try execute("/usr/bin/codesign", ["--verify", "--strict", "--verbose=2", "--", finder.path])
    print("PASS: Embedded Finder extension signature")
    _ = try execute("/usr/bin/codesign", ["--verify", "--strict", "--verbose=2", "--", app.path])
    print("PASS: Main application signature")
    let appTeam = try signingTeam(at: app)
    let finderTeam = try signingTeam(at: finder)
    try require(appTeam == finderTeam, "Application and extension share Apple Developer Team \(appTeam)")
    let appGroups = try entitlementGroups(at: app)
    let finderGroups = try entitlementGroups(at: finder)
    try require(appGroups == finderGroups && appGroups.contains("group.com.wuhunyu.literight"),
                "Both bundles have the same LiteRight App Group entitlement")
    print("SIGNED BUNDLE VERIFIED. Finder approval, actual context-menu position, and TCC are not tested here.")
}

do {
    try main()
} catch {
    fputs("SIGNATURE_VERIFICATION_FAILURE: \(error)\n", stderr)
    exit(1)
}
