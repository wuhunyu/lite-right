import XCTest
@testable import LiteRightCore

final class OperationTargetTests: XCTestCase {
    func testDirectoryActionsResolveOnlyToDirectoryTarget() {
        let request = OperationRequest(action: .newText, directoryPath: "/tmp", terminalBundleID: nil)

        XCTAssertEqual(request.operationTarget, .directory(URL(fileURLWithPath: "/tmp", isDirectory: true)))
    }

    func testCopyActionKeepsSelectedFileAsAbsolutePathTarget() {
        let file = URL(fileURLWithPath: "/tmp/report.md")
        let request = OperationRequest(action: .copyDirectoryPath, directoryPath: file.path, terminalBundleID: nil)

        XCTAssertEqual(request.operationTarget, .absolutePath(file))
    }

    func testMissingPathDoesNotProduceAnOperationTarget() {
        let request = OperationRequest(action: .copyDirectoryPath, directoryPath: nil, terminalBundleID: nil)

        XCTAssertNil(request.operationTarget)
    }
}
