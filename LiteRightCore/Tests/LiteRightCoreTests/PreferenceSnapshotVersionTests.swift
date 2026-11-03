import XCTest
@testable import LiteRightCore

final class PreferenceSnapshotVersionTests: XCTestCase {
    func testLegacyPreferencesGainCurrentSchemaAndZeroRevision() throws {
        let legacy = Data(#"{"orderedMenuItems":[{"id":"newMarkdown","isVisible":false}]}"#.utf8)

        let restored = try JSONDecoder().decode(GeneralPreferences.self, from: legacy)

        XCTAssertEqual(restored.schemaVersion, GeneralPreferences.currentSchemaVersion)
        XCTAssertEqual(restored.revision, 0)
        XCTAssertFalse(try XCTUnwrap(restored.orderedMenuItems.first { $0.id == .newMarkdown }).isVisible)
    }

    func testRevisionRoundTripsAndAdvances() throws {
        var preferences = GeneralPreferences.default
        preferences.advanceRevision()
        preferences.advanceRevision()

        let bytes = try JSONEncoder().encode(preferences)
        let restored = try JSONDecoder().decode(GeneralPreferences.self, from: bytes)

        XCTAssertEqual(restored.schemaVersion, GeneralPreferences.currentSchemaVersion)
        XCTAssertEqual(restored.revision, 2)
    }

    func testRejectsUnsupportedSnapshotSchema() {
        let future = Data(#"{"schemaVersion":99,"revision":12}"#.utf8)

        XCTAssertThrowsError(try JSONDecoder().decode(GeneralPreferences.self, from: future))
    }
}
