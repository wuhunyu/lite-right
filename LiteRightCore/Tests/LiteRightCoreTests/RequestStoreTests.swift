import XCTest
@testable import LiteRightCore

final class RequestStoreTests: XCTestCase {
    func testExactlyOnceClaimAndCompletion() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = try RequestStore(baseDirectory: root)
        let req = OperationRequest(action: .openInTerminal, directoryPath: "/tmp", terminalBundleID: .terminal)
        try store.save(req)
        XCTAssertEqual(try store.claim(id: req.id).id, req.id)
        XCTAssertThrowsError(try store.claim(id: req.id))
        try store.complete(id: req.id)
        XCTAssertThrowsError(try store.claim(id: req.id))
    }
    func testExpiredAndFutureRequestRejected() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = try RequestStore(baseDirectory: root)
        let req = OperationRequest(action: .toggleHiddenFiles, directoryPath: nil, terminalBundleID: nil, createdAt: Date(timeIntervalSinceNow: -120))
        try store.save(req)
        XCTAssertThrowsError(try store.claim(id: req.id))
    }
}
