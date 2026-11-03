import CoreGraphics
import Foundation

/// Reproduce Finder's physical Command-Shift-Period keyboard shortcut.
/// The events are constructed separately from posting so CI can inspect the
/// exact key codes, modifier flags and key-up cleanup without injecting input.
public enum FinderHiddenFileShortcut {
    public static func makeEvents() throws -> [CGEvent] {
        // ANSI Command=55, Shift=56, Period=47. AppleScript Unicode
        // keystroke "." is not a reliable substitute for the physical key.
        let steps: [(key: CGKeyCode, down: Bool, flags: CGEventFlags)] = [
            (55, true, [.maskCommand]),
            (56, true, [.maskCommand, .maskShift]),
            (47, true, [.maskCommand, .maskShift]),
            (47, false, [.maskCommand, .maskShift]),
            (56, false, [.maskCommand]),
            (55, false, [])
        ]
        return try steps.map { step in
            guard let event = CGEvent(
                keyboardEventSource: nil,
                virtualKey: step.key,
                keyDown: step.down
            ) else {
                throw LiteRightError.operationFailed("无法创建 Finder 快捷键事件。")
            }
            event.flags = step.flags
            return event
        }
    }
    /// Deliver the physical shortcut directly to the intended Finder process.
    /// A global HID tap can race with LaunchServices bringing LiteRight to
    /// the foreground. The injected closure allows CI to verify the actual
    /// destination of all six events without sending keyboard input.
    public static func post(
        to finderPID: pid_t,
        deliver: (CGEvent, pid_t) -> Void = { event, pid in event.postToPid(pid) }
    ) throws {
        guard finderPID > 0 else {
            throw LiteRightError.operationFailed("Finder 进程无效，未发送快捷键。")
        }
        for event in try makeEvents() {
            deliver(event, finderPID)
        }
    }
}
