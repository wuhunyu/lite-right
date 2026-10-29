import XCTest
@testable import LiteRightCore

final class MonitoredFoldersTests: XCTestCase {
    func testNormalizeCanonicalizesAndDeduplicatesAbsolutePaths() {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("LiteRight Monitor Test", isDirectory: true).standardizedFileURL.path
        let result = MonitoredFolders.normalize([
            root, root + "/", root + "/nested/..",
            "relative/folder", "/", "", root
        ])
        XCTAssertEqual(result, [root])
    }

    func testRegistrationRootsDoNotRequireSandboxFileSystemAccess() {
        let offlinePath = "/Volumes/LiteRight-Not-Mounted-\(UUID().uuidString)"
        let expected = URL(fileURLWithPath: offlinePath, isDirectory: true).standardizedFileURL
        XCTAssertEqual(MonitoredFolders.registrationDirectoryURLs([offlinePath]), Set([expected]))
    }

    func testRegistrationCollapsesNestedRootsWithoutStattingDirectories() {
        let roots = ["/Users/literight-example", "/Users/literight-example/Documents"]
        XCTAssertEqual(
            MonitoredFolders.registrationDirectoryURLs(roots),
            Set([URL(fileURLWithPath: roots[0], isDirectory: true).standardizedFileURL])
        )
    }

    func testDefaultFinderRootUsesLoginAccountHomeNotSandboxContainer() {
        XCTAssertEqual(GeneralPreferences.default.monitoredFolderPaths,
                       [UserHomeDirectory.current()])
    }

    func testUnavailableExternalVolumeStaysConfiguredButIsNotWatched() {
        let missing = "/Volumes/LiteRight-Unplugged-\(UUID().uuidString)"
        XCTAssertEqual(MonitoredFolders.normalize([missing]), [missing])
        XCTAssertTrue(MonitoredFolders.activeDirectoryURLs([missing]).isEmpty)
    }

    func testActiveWatchRootsExcludeNestedDuplicates() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let nested = root.appendingPathComponent("nested", isDirectory: true)
        try FileManager.default.createDirectory(at: nested, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        XCTAssertEqual(
            MonitoredFolders.activeDirectoryURLs([nested.path, root.path, root.path]),
            Set([root.standardizedFileURL])
        )
    }

    func testUnicodeAndSpacesRoundTrip() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("监控 目录 \(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        XCTAssertEqual(MonitoredFolders.activeDirectoryURLs([root.path]), Set([root.standardizedFileURL]))
    }

    func testPreferenceNormalizationUsesMonitoredFolderRules() {
        var prefs = GeneralPreferences.default
        prefs.monitoredFolderPaths = ["/", "relative", "/Volumes/LiteRight Demo/", "/Volumes/LiteRight Demo"]
        XCTAssertEqual(prefs.normalized().monitoredFolderPaths, ["/Volumes/LiteRight Demo"])
    }
}
