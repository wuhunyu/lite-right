import AppKit
import SwiftUI
import LiteRightCore

@MainActor
final class OperationDispatcher: ObservableObject {
    func handleIncomingURL(_ url: URL) async {
        guard url.scheme == "lite-right", url.host == "run",
              let params = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let idText = params.queryItems?.first(where: { $0.name == "id" })?.value,
              let id = UUID(uuidString: idText) else { return }
        do {
            let store = try RequestStore()
            let req = try store.claim(id: id)
            defer { try? store.complete(id: id) }
            switch req.action {
            case .newText, .newMarkdown:
                let directory = try validatedRequestDirectory(req)
                _ = try AtomicFileCreator.createFile(
                    in: directory, template: req.action == .newText ? .text : .markdown
                )
            case .copyDirectoryPath:
                let directory = try validatedRequestDirectory(req)
                NSPasteboard.general.clearContents()
                guard NSPasteboard.general.setString(directory.path, forType: .string) else {
                    throw LiteRightError.operationFailed("无法复制目录路径。")
                }
            case .openInTerminal:
                let directory = try validatedRequestDirectory(req)
                let preferences = try HostPreferencesStore().load()
                try await TerminalLauncher.openDirectory(directory, preferences: preferences)
            case .toggleHiddenFiles:
                let preferences = try HostPreferencesStore().load()
                try await HiddenFilesController.toggle(preferences: preferences)
            }
        } catch {
            let alert = NSAlert(error: error)
            alert.runModal()
        }
    }

    private func validatedRequestDirectory(_ req: OperationRequest) throws -> URL {
        guard let rawPath = req.directoryPath,
              let directory = TargetResolver.validatedDirectory(
                URL(fileURLWithPath: rawPath, isDirectory: true)
              ) else {
            throw LiteRightError.invalidDirectory
        }
        return directory
    }
}
