import Foundation

/// Bounded, time-based replay protection for short-lived preview requests.
public struct RequestDeduplicator: Sendable {
    private let capacity: Int
    private let lifetime: TimeInterval
    private var receivedAt: [UUID: Date] = [:]

    public init(capacity: Int = 256, lifetime: TimeInterval = 60) {
        self.capacity = max(1, capacity)
        self.lifetime = max(0, lifetime)
    }

    /// Returns `false` when the identifier is still inside its replay window.
    @discardableResult
    public mutating func insert(_ id: UUID, at now: Date = Date()) -> Bool {
        receivedAt = receivedAt.filter { now.timeIntervalSince($0.value) < lifetime }
        guard receivedAt[id] == nil else { return false }

        if receivedAt.count >= capacity,
           let oldest = receivedAt.min(by: { $0.value < $1.value })?.key {
            receivedAt.removeValue(forKey: oldest)
        }
        receivedAt[id] = now
        return true
    }
}
