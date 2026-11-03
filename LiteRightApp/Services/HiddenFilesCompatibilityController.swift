import AppKit
import Foundation
import LiteRightCore
import os

/// Finder has no supported public API that guarantees immediate hidden-file
/// refresh from an external app without its native keyboard shortcut.
/// This is a separately confirmed, compatibility-only Finder relaunch route.
@MainActor
enum HiddenFilesCompatibilityController {
    private static let logger = Logger(subsystem: "com.wuhunyu.literight", category: "hidden-files")

    /// Offer the user a deliberate show/hide choice after the shortcut fails.
    /// Never silently run the compatibility method.
    static func offerAfterShortcutFailure(_ failure: Error) throws -> Bool {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "无重启方式未能完成隐藏文件切换"
        alert.informativeText = "\(failure.localizedDescription)\n\n可以改用兼容模式：直接设置显示或隐藏，然后重启 Finder。此操作可能中断正在使用的 Finder 窗口。请选择明确的目标状态，或取消。"
        alert.addButton(withTitle: "显示隐藏文件并重启 Finder")
        alert.addButton(withTitle: "隐藏隐藏文件并重启 Finder")
        alert.addButton(withTitle: "取消")
        NSApp.activate(ignoringOtherApps: true)
        let choice: FinderHiddenFilesFallback.Choice
        switch alert.runModal() {
        case .alertFirstButtonReturn: choice = .show
        case .alertSecondButtonReturn: choice = .hide
        default: choice = .cancel
        }
        return try run(choice)
    }

    /// The same operation can be launched directly from Settings even when
    /// the Finder Sync right-click extension's request transport is broken.
    static func confirm(showing: Bool) throws -> Bool {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = showing ? "使用兼容模式显示隐藏文件？" : "使用兼容模式隐藏隐藏文件？"
        alert.informativeText = "该操作会修改 Finder 的 AppleShowAllFiles 设置并重启 Finder。正在使用的 Finder 窗口可能会中断。不会修改、移动或删除任何文件。"
        alert.addButton(withTitle: "确认并重启 Finder")
        alert.addButton(withTitle: "取消")
        NSApp.activate(ignoringOtherApps: true)
        guard alert.runModal() == .alertFirstButtonReturn else { return false }
        return try run(showing ? .show : .hide)
    }

    private static func run(_ choice: FinderHiddenFilesFallback.Choice) throws -> Bool {
        let applied = try FinderHiddenFilesFallback.apply(
            choice,
            updatePreference: { try writeFinderPreference(showing: $0) },
            restartFinder: { try restartFinder() }
        )
        if applied {
            logger.notice("hidden_compatibility_restart_requested")
        } else {
            logger.notice("hidden_compatibility_cancelled")
        }
        return applied
    }

    private static func writeFinderPreference(showing: Bool) throws {
        let domain = "com.apple.finder" as CFString
        CFPreferencesSetAppValue(
            "AppleShowAllFiles" as CFString,
            showing ? kCFBooleanTrue : kCFBooleanFalse,
            domain
        )
        guard CFPreferencesAppSynchronize(domain) else {
            logger.error("hidden_compatibility_preference_write_failed")
            throw LiteRightError.operationFailed("无法保存 Finder 隐藏文件显示设置；Finder 未重启。")
        }
    }

    private static func restartFinder() throws {
        // Direct executable invocation, no shell or interpolated arguments.
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/killall")
        process.arguments = ["Finder"]
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            logger.error("hidden_compatibility_restart_launch_failed")
            throw LiteRightError.operationFailed("Finder 偏好已写入，但未能启动 Finder 重启操作：\(error.localizedDescription)")
        }
        guard process.terminationReason == .exit, process.terminationStatus == 0 else {
            logger.error("hidden_compatibility_restart_failed exit_status=\(process.terminationStatus)")
            throw LiteRightError.operationFailed("Finder 偏好已写入，但 Finder 重启失败（退出码 \(process.terminationStatus)）。")
        }
    }
}
