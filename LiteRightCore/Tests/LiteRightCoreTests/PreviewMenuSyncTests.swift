import XCTest
@testable import LiteRightCore

final class PreviewMenuSyncTests: XCTestCase {
    func testMenuVisibilityOrderAndTerminalSurviveSnapshot() throws {
        var preferences = GeneralPreferences.default
        preferences.orderedMenuItems.reverse()
        preferences.orderedMenuItems[0].isVisible = false
        preferences.preferredTerminal = .iTerm2
        let encoded = try XCTUnwrap(PreviewMenuSync.encode(preferences))
        let restored = try XCTUnwrap(PreviewMenuSync.decode(encoded))
        XCTAssertEqual(restored.orderedMenuItems, preferences.orderedMenuItems)
        XCTAssertEqual(restored.preferredTerminal, .iTerm2)
    }

    func testRejectsMalformedOrOversizedSnapshots() {
        XCTAssertNil(PreviewMenuSync.decode("bad"))
        XCTAssertNil(PreviewMenuSync.decode(String(repeating: "A", count: 70_000)))
    }
}
