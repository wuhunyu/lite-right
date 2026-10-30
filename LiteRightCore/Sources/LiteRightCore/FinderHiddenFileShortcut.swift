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
}
