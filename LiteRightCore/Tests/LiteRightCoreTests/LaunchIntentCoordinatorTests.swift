import XCTest
@testable import LiteRightCore

final class LaunchIntentCoordinatorTests: XCTestCase {
    func testFinderOperationSuppressesColdLaunchSettingsPresentation() {
        var coordinator = LaunchIntentCoordinator()
        let now = Date(timeIntervalSince1970: 1_000)
        coordinator.recordOperationURL(at: now)

        XCTAssertFalse(coordinator.shouldPresentSettings(afterColdLaunch: true, at: now.addingTimeInterval(1)))
    }

    func testRecentFinderOperationSuppressesReopenButNotLaterManualOpen() {
        var coordinator = LaunchIntentCoordinator()
        let now = Date(timeIntervalSince1970: 1_000)
        coordinator.recordOperationURL(at: now)

        XCTAssertFalse(coordinator.shouldPresentSettings(afterColdLaunch: false, at: now.addingTimeInterval(0.6)))
        XCTAssertTrue(coordinator.shouldPresentSettings(afterColdLaunch: false, at: now.addingTimeInterval(0.8)))
    }
}
