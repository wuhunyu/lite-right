import XCTest
@testable import LiteRightCore

final class FinderHiddenFilesFallbackTests: XCTestCase {
    func testCancelNeverChangesPreferencesOrRestartsFinder() throws {
        var preferenceWrites = 0
        var finderRestarts = 0
        let applied = try FinderHiddenFilesFallback.apply(
            .cancel,
            updatePreference: { _ in preferenceWrites += 1 },
            restartFinder: { finderRestarts += 1 }
        )
        XCTAssertFalse(applied)
        XCTAssertEqual(preferenceWrites, 0)
        XCTAssertEqual(finderRestarts, 0)
    }

    func testExplicitShowUpdatesPreferenceThenRestarts() throws {
        var steps: [String] = []
        let applied = try FinderHiddenFilesFallback.apply(
            .show,
            updatePreference: { show in steps.append("write:\(show)") },
            restartFinder: { steps.append("restart") }
        )
        XCTAssertTrue(applied)
        XCTAssertEqual(steps, ["write:true", "restart"])
    }

    func testExplicitHideUpdatesPreferenceThenRestarts() throws {
        var steps: [String] = []
        let applied = try FinderHiddenFilesFallback.apply(
            .hide,
            updatePreference: { show in steps.append("write:\(show)") },
            restartFinder: { steps.append("restart") }
        )
        XCTAssertTrue(applied)
        XCTAssertEqual(steps, ["write:false", "restart"])
    }

    func testFailedPreferenceWriteNeverRestartsFinder() {
        enum TestError: Error { case denied }
        var restarts = 0
        XCTAssertThrowsError(
            try FinderHiddenFilesFallback.apply(
                .show,
                updatePreference: { _ in throw TestError.denied },
                restartFinder: { restarts += 1 }
            )
        )
        XCTAssertEqual(restarts, 0)
    }
}
