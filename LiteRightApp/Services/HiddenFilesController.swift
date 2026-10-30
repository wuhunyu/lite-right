import AppKit
import ApplicationServices
import LiteRightCore

@MainActor
enum HiddenFilesController {
    static func toggle(preferences _: GeneralPreferences) async throws {
        guard AXIsProcessTrusted() else {
            throw LiteRightError.operationFailed("需要辅助功能授权才能通过 Finder 快捷键切换隐藏文件。请在系统设置 → 隐私与安全性 → 辅助功能中允许 LiteRight。")
        }

        // Finder's own Cmd-Shift-. command updates its windows in place.
        // Do not kill Finder or modify its preferences behind its back.
        let script = """
        tell application "Finder" to activate
        delay 0.15
        tell application "System Events"
            tell process "Finder"
                set frontmost to true
                keystroke "." using {command down, shift down}
            end tell
        end tell
        """
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        task.arguments = ["-e", script]
        let errorPipe = Pipe()
        task.standardError = errorPipe
        try task.run()
        task.waitUntilExit()
        guard task.terminationStatus == 0 else {
            let details = String(data: errorPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            throw LiteRightError.operationFailed("Finder 快捷键执行失败。请确认 LiteRight 的辅助功能和自动化授权。\n\(details)")
        }
    }
}
