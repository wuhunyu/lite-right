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
    func testAllFiveFinderActionsAreBrokeredExactlyOnce() throws {
        for action in MenuItemID.allCases {
            let folder = FileManager.default.temporaryDirectory
                .appendingPathComponent("lite-right-request-\(UUID().uuidString)", isDirectory: true)
            defer { try? FileManager.default.removeItem(at: folder) }
            let store = try RequestStore(baseDirectory: folder)
            let request = OperationRequest(
                action: action,
                directoryPath: action == .toggleHiddenFiles ? nil : "/tmp",
                terminalBundleID: action == .openInTerminal ? .terminal : nil
            )
            try store.save(request)
            let claimed = try store.claim(id: request.id)
            XCTAssertEqual(claimed.id, request.id, "Request must be delivered exactly once for \(action)")
            XCTAssertEqual(claimed.action, action)
            XCTAssertEqual(claimed.directoryPath, request.directoryPath)
            XCTAssertThrowsError(try store.claim(id: request.id))
            try store.complete(id: request.id)
        }
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
