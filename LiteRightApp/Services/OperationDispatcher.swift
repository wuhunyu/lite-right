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
            case .openInTerminal:
                guard let rawPath = req.directoryPath,
                      let directory = TargetResolver.validatedDirectory(URL(fileURLWithPath: rawPath, isDirectory: true)) else {
                    throw LiteRightError.invalidDirectory
                }
                try await TerminalLauncher.openDirectory(directory, preferences: SharedPreferences().load())
            case .toggleHiddenFiles:
                try await HiddenFilesController.toggle(preferences: SharedPreferences().load())
            default: throw LiteRightError.unsupportedAction
            }
        } catch {
            let alert = NSAlert(error: error)
            alert.runModal()
        }
    }
}
