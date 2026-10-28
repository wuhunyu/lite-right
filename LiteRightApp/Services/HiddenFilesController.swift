import AppKit
import ApplicationServices
import LiteRightCore

@MainActor
enum HiddenFilesController {
    static func toggle(preferences: GeneralPreferences) async throws {
        if preferences.useAccessibilityToggleForHiddenFiles {
            guard AXIsProcessTrusted() else { throw LiteRightError.permissionDenied }
            guard NSWorkspace.shared.frontmostApplication?.bundleIdentifier == "com.apple.finder" else {
                throw LiteRightError.operationFailed("请先切换到 Finder，再使用快捷键模式。")
            }
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
            task.arguments = ["-e", "tell application \"System Events\" to keystroke \".\" using {command down, shift down}"]
            try task.run(); task.waitUntilExit()
            guard task.terminationStatus == 0 else { throw LiteRightError.operationFailed("快捷键发送失败，请检查辅助功能授权。") }
        } else {
            let finderDomain = "com.apple.finder"
            let current = CFPreferencesCopyAppValue("AppleShowAllFiles" as CFString, finderDomain as CFString) as? Bool ?? false
            let alert = NSAlert()
            alert.messageText = current ? "隐藏 Finder 隐藏文件？" : "显示 Finder 隐藏文件？"
            alert.informativeText = "此设置影响整个 Finder。需要重新启动 Finder 才能完整生效。"
            alert.addButton(withTitle: "修改并重新启动 Finder")
            alert.addButton(withTitle: "取消")
            guard alert.runModal() == .alertFirstButtonReturn else { return }
            CFPreferencesSetAppValue("AppleShowAllFiles" as CFString, !current as CFPropertyList, finderDomain as CFString)
            guard CFPreferencesAppSynchronize(finderDomain as CFString) else { throw LiteRightError.operationFailed("无法保存 Finder 偏好。") }
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/usr/bin/killall")
            task.arguments = ["Finder"]
            try task.run(); task.waitUntilExit()
            guard task.terminationStatus == 0 else { throw LiteRightError.operationFailed("Finder 偏好已更新，请手动重新启动 Finder。") }
        }
    }
}
