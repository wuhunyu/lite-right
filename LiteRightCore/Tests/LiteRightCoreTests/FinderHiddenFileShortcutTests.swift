import CoreGraphics
import XCTest
@testable import LiteRightCore

final class FinderHiddenFileShortcutTests: XCTestCase {
    func testHardwareKeySequenceMatchesCommandShiftPeriod() throws {
        let events = try FinderHiddenFileShortcut.makeEvents()
        XCTAssertEqual(events.map { $0.getIntegerValueField(.keyboardEventKeycode) },
                       [55, 56, 47, 47, 56, 55])
        XCTAssertEqual(events[2].type, .keyDown)
        XCTAssertEqual(events[3].type, .keyUp)
        XCTAssertTrue(events[2].flags.contains(.maskCommand))
        XCTAssertTrue(events[2].flags.contains(.maskShift))
        XCTAssertTrue(events[3].flags.contains(.maskCommand))
        XCTAssertTrue(events[3].flags.contains(.maskShift))
        XCTAssertFalse(events[5].flags.contains(.maskCommand))
        XCTAssertFalse(events[5].flags.contains(.maskShift))
    }

    func testShortcutReleasesEachPressedModifier() throws {
        let events = try FinderHiddenFileShortcut.makeEvents()
        XCTAssertEqual(events.count, 6)
        XCTAssertEqual(events[0].getIntegerValueField(.keyboardEventKeycode),
                       events[5].getIntegerValueField(.keyboardEventKeycode))
        XCTAssertEqual(events[1].getIntegerValueField(.keyboardEventKeycode),
                       events[4].getIntegerValueField(.keyboardEventKeycode))
        XCTAssertTrue(events[0].flags.contains(.maskCommand))
        XCTAssertTrue(events[1].flags.contains(.maskShift))
        XCTAssertFalse(events[4].flags.contains(.maskShift))
    }
}
