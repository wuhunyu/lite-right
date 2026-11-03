import Foundation
import XCTest
@testable import LiteRightCore

final class AsyncProcessRunnerTests: XCTestCase {
    func testReturnsExitStatusWithoutBlockingCaller() async throws {
        let result = try await AsyncProcessRunner.run(
            executableURL: URL(fileURLWithPath: "/usr/bin/true"),
            arguments: [],
            timeout: .seconds(2)
        )

        XCTAssertEqual(result.terminationStatus, 0)
    }

    func testCapturesStandardErrorWithoutPipeDeadlock() async throws {
        let result = try await AsyncProcessRunner.run(
            executableURL: URL(fileURLWithPath: "/bin/sh"),
            arguments: ["-c", "printf 'terminal diagnostic' >&2"],
            timeout: .seconds(2)
        )

        XCTAssertEqual(result.terminationStatus, 0)
        XCTAssertEqual(result.standardError, "terminal diagnostic")
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
