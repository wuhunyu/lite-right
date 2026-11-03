import Foundation
import XCTest
@testable import LiteRightCore

final class AsyncProcessRunnerTests: XCTestCase {
    func testReturnsExitStatusWithoutBlockingCaller() async throws {
        let status = try await AsyncProcessRunner.run(
            executableURL: URL(fileURLWithPath: "/usr/bin/true"),
            arguments: [],
            timeout: .seconds(2)
        )

        XCTAssertEqual(status, 0)
    }

    func testTerminatesProcessWhenTimeoutExpires() async {
        do {
            _ = try await AsyncProcessRunner.run(
                executableURL: URL(fileURLWithPath: "/bin/sleep"),
                arguments: ["5"],
                timeout: .milliseconds(50)
            )
            XCTFail("The runner must report a timed out process")
        } catch AsyncProcessRunnerError.timedOut {
            // Expected.
        } catch {
            XCTFail("Unexpected process runner error: \(error)")
        }
    }
}
