import Foundation
import XCTest
@testable import LiteRightCore

final class UserHomeDirectoryTests: XCTestCase {
    private let sandboxHome = "/Users/fixture/Library/Containers/com.wuhunyu.literight.finder/Data"

    func testLoginAccountPathWinsOverSandboxedFoundationHome() {
        XCTAssertEqual(
            UserHomeDirectory.resolve(accountHome: "/Users/fixture", foundationHome: sandboxHome),
            "/Users/fixture"
        )
    }

    func testMissingAccountPathDoesNotSilentlyWatchSandboxContainer() {
        XCTAssertEqual(
            UserHomeDirectory.resolve(accountHome: nil, foundationHome: sandboxHome),
            ""
        )
    }

    func testRejectsRelativeOrFilesystemRootAccountPath() {
        XCTAssertEqual(UserHomeDirectory.resolve(accountHome: "Users/fixture", foundationHome: sandboxHome), "")
        XCTAssertEqual(UserHomeDirectory.resolve(accountHome: "/", foundationHome: sandboxHome), "")
    }

    func testNormalizesValidAccountHome() {
        XCTAssertEqual(
            UserHomeDirectory.resolve(accountHome: "/Users/fixture/../fixture", foundationHome: sandboxHome),
            "/Users/fixture"
        )
    }
}
