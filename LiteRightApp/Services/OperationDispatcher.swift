import AppKit
import SwiftUI
import LiteRightCore
import os

@MainActor
final class OperationDispatcher: ObservableObject {
    private let logger = Logger(subsystem: "com.wuhunyu.literight", category: "operations")
    #if DEBUG || LITERIGHT_UNTRUSTED_PREVIEW
    private var seenPreviewRequests = Set<UUID>()
    private var recentPreviewRequests: [Date] = []
    #endif

    func handleIncomingURL(_ url: URL) async {
        guard url.scheme == "lite-right", url.host == "run" else { return }
        do {
            guard let params = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
                throw LiteRightError.requestUnavailable
            }

            #if DEBUG || LITERIGHT_UNTRUSTED_PREVIEW
            // Only the explicit unsigned-preview transport accepts a request
            // body in the URL. Signed release builds keep the UUID/App Group
            // transport and cannot be triggered by arbitrary request payloads.
            if params.queryItems?.contains(where: { $0.name == "request" }) == true {
                let request = try PreviewRequestLink.decode(url)
                guard seenPreviewRequests.insert(request.id).inserted else {
                    throw LiteRightError.requestAlreadyProcessed
                }
                let now = Date()
                recentPreviewRequests.removeAll { now.timeIntervalSince($0) > 60 }
                guard recentPreviewRequests.count < 30 else {
                    throw LiteRightError.operationFailed("一分钟内的操作次数过多，请稍后再试。")
                }
                recentPreviewRequests.append(now)
                logger.notice("preview_request_received action=\(request.action.rawValue, privacy: .public)")
                try await execute(request, requireMonitoredRoot: true)
                logger.notice("preview_request_completed action=\(request.action.rawValue, privacy: .public)")
                return
            }
            #endif

            guard params.user == nil, params.password == nil, params.port == nil,
                  params.fragment == nil, params.path.isEmpty,
                  let queryItems = params.queryItems, queryItems.count == 1,
                  queryItems[0].name == "id",
                  let idText = queryItems[0].value,
                  let id = UUID(uuidString: idText) else {
                throw LiteRightError.requestUnavailable
            }
            let store = try RequestStore()
            let request = try store.claim(id: id)
            defer { try? store.complete(id: id) }
            logger.notice("app_group_request_received action=\(request.action.rawValue, privacy: .public)")
            try await execute(request, requireMonitoredRoot: false)
            logger.notice("app_group_request_completed action=\(request.action.rawValue, privacy: .public)")
        } catch {
            logger.error("operation_failed details=\(String(describing: error), privacy: .private)")
            // LiteRight can run as an accessory app without a Dock icon.
            // Activate explicitly so the user sees errors instead of silence.
            NSApp.activate(ignoringOtherApps: true)
            NSAlert(error: error).runModal()
        }
    }

    private func execute(_ request: OperationRequest, requireMonitoredRoot: Bool) async throws {
        switch request.action {
        case .newText, .newMarkdown:
            let directory = try validatedRequestDirectory(request, requireMonitoredRoot: requireMonitoredRoot)
            _ = try AtomicFileCreator.createFile(
                in: directory, template: request.action == .newText ? .text : .markdown
            )
        case .copyDirectoryPath:
            let directory = try validatedRequestDirectory(request, requireMonitoredRoot: requireMonitoredRoot)
            NSPasteboard.general.clearContents()
            guard NSPasteboard.general.setString(directory.path, forType: .string) else {
                throw LiteRightError.operationFailed("无法复制目录路径。")
            }
        case .openInTerminal:
            let directory = try validatedRequestDirectory(request, requireMonitoredRoot: requireMonitoredRoot)
            let preferences = try HostPreferencesStore().load()
            try await TerminalLauncher.openDirectory(directory, preferences: preferences)
        case .toggleHiddenFiles:
            let preferences = try HostPreferencesStore().load()
            try await HiddenFilesController.toggle(preferences: preferences)
        }
    }

    private func validatedRequestDirectory(
        _ request: OperationRequest, requireMonitoredRoot: Bool
    ) throws -> URL {
        guard let rawPath = request.directoryPath,
              let directory = TargetResolver.validatedDirectory(
                URL(fileURLWithPath: rawPath, isDirectory: true)
              ) else {
            throw LiteRightError.invalidDirectory
        }
        if requireMonitoredRoot {
            // The caller of a custom URL scheme is untrusted. Re-validate the
            // actual directory and configured roots in the privileged host,
            // resolving symlinks before checking component-boundary coverage.
            let preferences = try HostPreferencesStore().load()
            let roots = Set(preferences.monitoredFolderPaths.compactMap {
                TargetResolver.validatedDirectory(URL(fileURLWithPath: $0, isDirectory: true))
            })
            guard MonitoredFolders.covers(directory, registeredRoots: roots) else {
                throw LiteRightError.operationFailed(
                    "请求的目录不在 LiteRight 配置的 Finder 监控范围内。"
                )
            }
        }
        return directory
    }
}
