import XCTest
@testable import LiteRightCore

/// Finder copies menu items between processes: representedObject is not
/// retained, but integer tags are. This tests the only supported payload.
final class FinderActionTagTests: XCTestCase {
    func testAllActionsAndContextsRoundTripThroughIntegerTagOnly() {
        let contexts: [FinderMenuContext] = [.items, .container, .sidebar]
        var tags = Set<Int>()
        for context in contexts {
            for action in MenuItemID.allCases {
                guard let tag = FinderActionTag.tag(for: action, context: context) else {
                    XCTFail("Missing tag for \(action) in \(context)")
                    continue
                }
                XCTAssertTrue(tags.insert(tag).inserted, "All menu entries need distinct stable tags")
                let resolved = FinderActionTag.resolve(tag: tag)
                XCTAssertEqual(resolved?.action, action)
                XCTAssertEqual(String(describing: resolved?.context), String(describing: Optional(context)))
            }
        }
        XCTAssertEqual(tags.count, MenuItemID.allCases.count * contexts.count)
    }

    func testUnsupportedTagsAndToolbarNeverBecomeOperations() {
        XCTAssertNil(FinderActionTag.tag(for: .newMarkdown, context: .toolbar))
        for tag in [-1, 0, 1, 99, 100, 106, 199, 206, 299, 306, 399, 401, 999, 10101] {
            XCTAssertNil(FinderActionTag.resolve(tag: tag), "Unexpected tag: \(tag)")
        }
    }
}
