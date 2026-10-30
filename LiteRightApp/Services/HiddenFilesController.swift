import AppKit
import CoreGraphics
import LiteRightCore
import os

@MainActor
enum HiddenFilesController {
    private static let logger = Logger(subsystem: "com.wuhunyu.literight", category: "hidden-files")

    static func toggle(preferences _: GeneralPreferences) async throws {
        // PostEvent is the permission required to send physical Quartz
        // keyboard events. Unlike AppleScript, no osascript/System Events
        // process or separate Automation permission is involved.
        guard CGPreflightPostEventAccess() else {
            _ = CGRequestPostEventAccess()
            logger.error("hidden_toggle_denied post_event_access=false")
            throw LiteRightError.operationFailed(
                "需要允许 LiteRight 控制电脑，才能发送 Finder 的 ⌘⇧. 快捷键。请在系统设置 → 隐私与安全性 → 辅助功能中授权，然后重新点击右键菜单。"
            )
        }

        guard let finder = NSRunningApplication.runningApplications(
            withBundleIdentifier: "com.apple.finder"
        ).first(where: { !$0.isTerminated }) else {
            throw LiteRightError.operationFailed("未找到 Finder 进程，无法切换隐藏文件显示。")
        }

        // lite-right:// URL dispatch may have activated the host app.
        // Finder must be active when its own keyboard shortcut is posted.
        let finderPID = finder.processIdentifier
        if NSWorkspace.shared.frontmostApplication?.processIdentifier != finderPID {
            guard finder.activate(options: [.activateIgnoringOtherApps]) else {
                throw LiteRightError.operationFailed("无法激活 Finder，因此未发送隐藏文件快捷键。")
            }
        }

        var finderIsFrontmost = false
        for _ in 0..<30 {
            if NSWorkspace.shared.frontmostApplication?.processIdentifier == finderPID {
                finderIsFrontmost = true
                break
            }
            try await Task.sleep(for: .milliseconds(60))
        }
        guard finderIsFrontmost else {
            logger.error("hidden_toggle_failed finder_focus_timeout")
            throw LiteRightError.operationFailed("Finder 未能取得前台焦点，快捷键未发送。")
        }

        // Check the Finder preference before and after the shortcut. Posting
        // Quartz events has no return value that proves Finder handled them.
        let before = currentState()
        let events = try FinderHiddenFileShortcut.makeEvents()
        logger.notice("hidden_toggle_posting finder_pid=\(finderPID) previous_state=\(String(describing: before), privacy: .public)")
        for event in events {
            event.post(tap: .cghidEventTap)
        }

        for _ in 0..<16 {
            try await Task.sleep(for: .milliseconds(90))
            let after = currentState()
            if let before, after == !before {
                logger.notice("hidden_toggle_verified new_state=\(after == true)")
                return
            }
            if before == nil, after != nil {
                logger.notice("hidden_toggle_posted prior_state_unavailable current_state=\(after == true)")
                return
            }
        }
        logger.error("hidden_toggle_unverified shortcut_posted_but_preference_unchanged")
        throw LiteRightError.operationFailed(
            "已发送 ⌘⇧.，但未检测到 Finder 隐藏文件状态发生变化。请确认 Finder 窗口已打开、LiteRight 已获得辅助功能权限；可手动按 ⌘⇧. 对照检查。"
        )
    }

    private static func currentState() -> Bool? {
        // Re-read cfprefsd rather than trusting an earlier cached value.
        _ = CFPreferencesAppSynchronize("com.apple.finder" as CFString)
        return FinderHiddenFilesState.isShowingHiddenFiles()
    }
}
