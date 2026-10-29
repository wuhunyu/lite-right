import XCTest
@testable import LiteRightCore

final class PreferencesTests: XCTestCase {
    func testDefaultsHaveAllFiveVisibleMenuItems() {
        XCTAssertEqual(GeneralPreferences.default.orderedMenuItems.map(\.id), MenuItemID.allCases)
        XCTAssertTrue(GeneralPreferences.default.orderedMenuItems.allSatisfy(\.isVisible))
    }
    func testRoundTripAndCorruptDataFallback() throws {
        let suite = "LiteRightTest-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = SharedPreferences(userDefaults: defaults)
        var prefs = GeneralPreferences.default
        prefs.orderedMenuItems.reverse()
        prefs.selectedShell = .fish
        try store.save(prefs)
        XCTAssertEqual(store.load().orderedMenuItems.map(\.id), prefs.orderedMenuItems.map(\.id))
        XCTAssertEqual(store.load().selectedShell, .fish)
        defaults.set(Data("broken".utf8), forKey: "generalPreferences")
        XCTAssertEqual(store.load(), .default)
    }
    func testSharedPreferencesReportsDeniedSynchronize() throws {
        let suite = "LiteRightRejectedGroup-\(UUID().uuidString)"
        let denied = RejectingUserDefaults(suiteName: suite)!
        defer { denied.removePersistentDomain(forName: suite) }
        XCTAssertThrowsError(try SharedPreferences(userDefaults: denied).save(.default),
                             "A cfprefsd-rejected write must not appear successful")
    }

    func testDuplicateAndMissingMenuIdsNormalized() throws {
        var prefs = GeneralPreferences.default
        prefs.orderedMenuItems = [MenuItemPreference(id: .newText, isVisible: false), MenuItemPreference(id: .newText, isVisible: true)]
        let clean = prefs.normalized()
        XCTAssertEqual(clean.orderedMenuItems.map(\.id), MenuItemID.allCases)
        XCTAssertFalse(clean.orderedMenuItems[0].isVisible)
    }
}

private final class RejectingUserDefaults: UserDefaults {
    override func synchronize() -> Bool { false }
}
