import XCTest
@testable import LiteRightCore

final class FinderHiddenFilesStateTests: XCTestCase {
    func testHiddenStateUsesShowAction() {
        let item = FinderHiddenFilesState.menuPresentation(showing: false)
        XCTAssertEqual(item.title, "显示隐藏文件")
        XCTAssertEqual(item.symbol, "eye")
    }

    func testVisibleStateUsesHideAction() {
        let item = FinderHiddenFilesState.menuPresentation(showing: true)
        XCTAssertEqual(item.title, "隐藏隐藏文件")
        XCTAssertEqual(item.symbol, "eye.slash")
    }

    func testUnknownStateDoesNotClaimVisibleOrHidden() {
        XCTAssertEqual(FinderHiddenFilesState.menuPresentation(showing: nil).title, "切换隐藏文件显示")
    }
}
