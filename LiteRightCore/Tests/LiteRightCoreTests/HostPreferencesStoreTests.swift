import Foundation
import XCTest
@testable import LiteRightCore

final class HostPreferencesStoreTests: XCTestCase {
    private func tempFile() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("literight-persistence-\(UUID().uuidString)", isDirectory: true)
            .appendingPathComponent("preferences.json")
    }

    func testLocalPreferencesSurviveRestartWithoutAppGroup() throws {
        let url = tempFile()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        var modified = GeneralPreferences.default
        modified.orderedMenuItems[1].isVisible = false
        modified.orderedMenuItems.reverse()
        modified.selectedShell = .fish
        modified.preferredTerminal = .iTerm2
        modified.showDockIcon = true
        modified.monitoredFolderPaths = ["/tmp/LiteRightTestFolder"]

        let first = HostPreferencesStore(fileURL: url, legacy: { .default })
        try first.save(modified)
        let second = HostPreferencesStore(fileURL: url, legacy: { .default })
        XCTAssertEqual(try second.load(), modified.normalized())
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
    }

    func testAbsentLocalSnapshotMigratesLegacyOnce() throws {
        let url = tempFile()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        var legacy = GeneralPreferences.default
        legacy.orderedMenuItems[0].isVisible = false
        let first = HostPreferencesStore(fileURL: url, legacy: { legacy })
        XCTAssertEqual(try first.load(), legacy)
        try first.save(legacy)
        let second = HostPreferencesStore(fileURL: url, legacy: { .default })
        XCTAssertEqual(try second.load(), legacy)
    }

    func testInvalidLocalSnapshotDoesNotSilentlyReset() throws {
        let url = tempFile()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(), withIntermediateDirectories: true
        )
        try Data("invalid json".utf8).write(to: url)
        XCTAssertThrowsError(try HostPreferencesStore(fileURL: url, legacy: { .default }).load())
    }

    func testSaveFailureIsReported() throws {
        let parentIsFile = FileManager.default.temporaryDirectory.appendingPathComponent(
            "literight-invalid-parent-\(UUID().uuidString)"
        )
        defer { try? FileManager.default.removeItem(at: parentIsFile) }
        XCTAssertTrue(FileManager.default.createFile(atPath: parentIsFile.path, contents: nil))
        let store = HostPreferencesStore(
            fileURL: parentIsFile.appendingPathComponent("preferences.json"),
            legacy: { .default }
        )
        XCTAssertThrowsError(try store.save(.default))
    }
}
