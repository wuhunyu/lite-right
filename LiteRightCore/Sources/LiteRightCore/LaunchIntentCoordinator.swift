import Foundation

/// Tracks whether delayed Settings presentation is still appropriate after
/// LaunchServices may deliver a Finder operation URL.
public struct LaunchIntentCoordinator: Sendable {
    private var receivedOperationURLThisLaunch = false
    private var lastOperationURLAt = Date.distantPast
    private let operationQuietPeriod: TimeInterval

    public init(operationQuietPeriod: TimeInterval = 0.7) {
        self.operationQuietPeriod = max(0, operationQuietPeriod)
    }

    public mutating func recordOperationURL(at date: Date = Date()) {
        receivedOperationURLThisLaunch = true
        lastOperationURLAt = date
    }

    public func shouldPresentSettings(afterColdLaunch: Bool, at date: Date = Date()) -> Bool {
        guard !(afterColdLaunch && receivedOperationURLThisLaunch) else { return false }
        return date.timeIntervalSince(lastOperationURLAt) > operationQuietPeriod
    }
}
