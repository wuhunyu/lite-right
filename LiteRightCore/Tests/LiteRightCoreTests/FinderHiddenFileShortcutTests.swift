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
    func testShortcutDeliveryIsDirectedToFinderPIDForEveryEvent() throws {
        let finderPID: pid_t = 4242
        var deliveredPIDs: [pid_t] = []
        var deliveredKeycodes: [Int64] = []
        var deliveredTypes: [CGEventType] = []

        // Injection prevents actual keyboard input while testing the same
        // routing sequence used by the production Finder operation.
        try FinderHiddenFileShortcut.post(to: finderPID) { event, pid in
            deliveredPIDs.append(pid)
            deliveredKeycodes.append(event.getIntegerValueField(.keyboardEventKeycode))
            deliveredTypes.append(event.type)
        }

        XCTAssertEqual(deliveredPIDs, Array(repeating: finderPID, count: 6))
        XCTAssertEqual(deliveredKeycodes, [55, 56, 47, 47, 56, 55])
        XCTAssertEqual(deliveredTypes, [.keyDown, .keyDown, .keyDown, .keyUp, .keyUp, .keyUp])
    }

    func testInvalidFinderPIDNeverPostsKeyboardEvents() {
        var eventCount = 0
        XCTAssertThrowsError(try FinderHiddenFileShortcut.post(to: 0) { _, _ in
            eventCount += 1
        })
        XCTAssertEqual(eventCount, 0)
    }
}
