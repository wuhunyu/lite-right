import AppKit
import Foundation
import LiteRightCore

@MainActor
enum TerminalLauncher {
    static func openDirectory(_ directory: URL, preferences: GeneralPreferences) async throws {
        guard TargetResolver.validatedDirectory(directory) != nil else { throw LiteRightError.invalidDirectory }
        guard NSWorkspace.shared.urlForApplication(withBundleIdentifier: preferences.preferredTerminal.rawValue) != nil else {
            throw LiteRightError.terminalUnavailable
        }
        guard ShellCatalog.canUse(preferences.selectedShell) else { throw LiteRightError.shellUnavailable }
        let path = ShellCatalog.path(for: preferences.selectedShell) ?? ""
        let script: String
        switch preferences.preferredTerminal {
        case .terminal:
            script = """
            on run argv
                set dir to item 1 of argv
                set shellExe to item 2 of argv
                set shouldClear to item 3 of argv
                set cmd to "cd -- " & quoted form of dir
                if shouldClear is "true" then set cmd to cmd & " && clear"
                if shellExe is not "" then set cmd to cmd & " && exec " & quoted form of shellExe & " -l"
                tell application "Terminal"
                    activate
                    do script cmd
                end tell
            end run
            """
        case .iTerm2:
            script = """
            on run argv
                set dir to item 1 of argv
                set shellExe to item 2 of argv
                set shouldClear to item 3 of argv
                set cmd to "cd -- " & quoted form of dir
                if shouldClear is "true" then set cmd to cmd & " && clear"
                if shellExe is not "" then set cmd to cmd & " && exec " & quoted form of shellExe & " -l"
                tell application id "com.googlecode.iterm2"
                    activate
                    set newWindow to (create window with default profile)
                    tell current session of newWindow
                        write text cmd
                    end tell
                end tell
            end run
            """
        }
        let result: AsyncProcessResult
        do {
            result = try await AsyncProcessRunner.run(
                executableURL: URL(fileURLWithPath: "/usr/bin/osascript"),
                arguments: ["-e", script, directory.path, path, preferences.clearAfterCD ? "true" : "false"],
                timeout: .seconds(30)
            )
        } catch AsyncProcessRunnerError.timedOut {
            throw LiteRightError.operationFailed("无法打开终端，等待终端响应超时。")
        }
        if result.terminationStatus != 0 {
            let detail = result.standardError
            throw LiteRightError.operationFailed("无法打开终端，请检查自动化授权。\n\(detail)")
        }
    }
}
