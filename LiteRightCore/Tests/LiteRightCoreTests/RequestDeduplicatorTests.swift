import XCTest
@testable import LiteRightCore

final class RequestDeduplicatorTests: XCTestCase {
    func testRejectsDuplicatesAndExpiresEntries() {
        var cache = RequestDeduplicator(capacity: 2, lifetime: 10)
        let start = Date(timeIntervalSince1970: 1_000)
        let first = UUID()

        XCTAssertTrue(cache.insert(first, at: start))
        XCTAssertFalse(cache.insert(first, at: start.addingTimeInterval(1)))
        XCTAssertTrue(cache.insert(first, at: start.addingTimeInterval(11)))
    }

    func testEvictsOldestEntryWhenCapacityIsReached() {
        var cache = RequestDeduplicator(capacity: 2, lifetime: 60)
        let start = Date(timeIntervalSince1970: 1_000)
        let first = UUID()
        let second = UUID()
        let third = UUID()

        XCTAssertTrue(cache.insert(first, at: start))
        XCTAssertTrue(cache.insert(second, at: start.addingTimeInterval(1)))
        XCTAssertTrue(cache.insert(third, at: start.addingTimeInterval(2)))
        XCTAssertTrue(cache.insert(first, at: start.addingTimeInterval(3)))
        XCTAssertFalse(cache.insert(third, at: start.addingTimeInterval(4)))
    }
}
