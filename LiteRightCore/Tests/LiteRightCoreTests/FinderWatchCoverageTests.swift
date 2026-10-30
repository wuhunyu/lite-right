import Foundation
import XCTest
@testable import LiteRightCore

final class FinderWatchCoverageTests: XCTestCase {
    func testLoginHomeRootCoversLocalTestDirectory() {
        let roots = MonitoredFolders.registrationDirectoryURLs(["/Users/fixture"])
        let localTest = URL(fileURLWithPath: "/Users/fixture/LiteRightLocalTest", isDirectory: true)
        XCTAssertTrue(MonitoredFolders.covers(localTest, registeredRoots: roots))
    }

    func testSandboxContainerFallbackDoesNotCoverLoginHome() {
        let roots = MonitoredFolders.registrationDirectoryURLs([
            "/Users/fixture/Library/Containers/com.wuhunyu.literight.finder/Data"
        ])
        let localTest = URL(fileURLWithPath: "/Users/fixture/LiteRightLocalTest", isDirectory: true)
        XCTAssertFalse(MonitoredFolders.covers(localTest, registeredRoots: roots))
    }

    func testWatchMatchesRootItself() {
        let roots = MonitoredFolders.registrationDirectoryURLs(["/Users/fixture/LiteRightLocalTest"])
        let localTest = URL(fileURLWithPath: "/Users/fixture/LiteRightLocalTest", isDirectory: true)
        XCTAssertTrue(MonitoredFolders.covers(localTest, registeredRoots: roots))
    }

    func testWatchDoesNotMatchSharedPrefixSibling() {
        let roots = MonitoredFolders.registrationDirectoryURLs(["/Users/fixture/LiteRightLocalTest"])
        let sibling = URL(fileURLWithPath: "/Users/fixture/LiteRightLocalTest2", isDirectory: true)
        XCTAssertFalse(MonitoredFolders.covers(sibling, registeredRoots: roots))
    }
}
