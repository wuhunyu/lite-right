import Foundation

// XcodeGen's info.path and entitlements.path rewrite the files on generation.
// Check the generated *on-disk* metadata, not only checked-in hand-edited plists.
enum MetadataError: Error, CustomStringConvertible {
    case invalid(String)
    var description: String { switch self { case let .invalid(message): message } }
}

func plist(_ path: String) throws -> [String: Any] {
    let data = try Data(contentsOf: URL(fileURLWithPath: path))
    guard let value = try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] else {
        throw MetadataError.invalid("Not a plist dictionary: \(path)")
    }
    return value
}

func require(_ ok: @autoclosure () -> Bool, _ message: String) throws {
    guard ok() else { throw MetadataError.invalid(message) }
    print("PASS: \(message)")
}

do {
    let app = try plist("LiteRightApp/Resources/AppInfo.plist")
    let extensionInfo = try plist("LiteRightFinderExtension/Info.plist")
    let appEntitlements = try plist("LiteRightApp/LiteRight.entitlements")
    let extensionEntitlements = try plist("LiteRightFinderExtension/LiteRightFinderExtension.entitlements")

    try require(app["LSUIElement"] as? Bool == true, "XcodeGen preserves LSUIElement")
    let urls = app["CFBundleURLTypes"] as? [[String: Any]] ?? []
    try require(urls.contains { ($0["CFBundleURLSchemes"] as? [String] ?? []).contains("lite-right") },
                "XcodeGen preserves lite-right URL scheme")
    try require(!(app["NSAppleEventsUsageDescription"] as? String ?? "").isEmpty,
                "XcodeGen preserves Apple Events usage description")

    let finder = extensionInfo["NSExtension"] as? [String: Any]
    try require(finder?["NSExtensionPointIdentifier"] as? String == "com.apple.FinderSync",
                "XcodeGen preserves Finder Sync extension point")
    try require((finder?["NSExtensionPrincipalClass"] as? String ?? "").contains("FinderSync"),
                "XcodeGen preserves Finder Sync entry class")

    let appGroups = appEntitlements["com.apple.security.application-groups"] as? [String] ?? []
    let extensionGroups = extensionEntitlements["com.apple.security.application-groups"] as? [String] ?? []
    try require(appGroups == ["group.com.wuhunyu.literight"],
                "XcodeGen preserves App Group entitlement in host")
    try require(extensionGroups == appGroups,
                "XcodeGen preserves App Group entitlement in Finder extension")
    print("Generated metadata verified; signature and actual Finder authorization require separate tests.")
} catch {
    fputs("GENERATED_METADATA_FAILURE: \(error)\n", stderr)
    exit(1)
}
