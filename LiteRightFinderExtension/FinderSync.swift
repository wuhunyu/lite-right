import Cocoa
import FinderSync
import LiteRightCore

final class FinderSync: FIFinderSync {
    private let storage = SharedPreferences()
    override init() {
        super.init()
        reloadMonitoredDirectories()
        DistributedNotificationCenter.default().addObserver(
            self, selector: #selector(monitoredFoldersChanged(_:)),
            name: Notification.Name(MonitoredFolders.didChangeNotification), object: nil
        )
    }

    deinit {
        DistributedNotificationCenter.default().removeObserver(self)
    }

    @objc private func monitoredFoldersChanged(_ notification: Notification) {
        reloadMonitoredDirectories()
    }

    private func reloadMonitoredDirectories() {
        let paths = storage.load().monitoredFolderPaths
        FIFinderSyncController.default().directoryURLs = MonitoredFolders.activeDirectoryURLs(paths)
    }

    override func menu(for menuKind: FIMenuKind) -> NSMenu? {
        let context: FinderMenuContext
        switch menuKind {
        case .contextualMenuForItems: context = .items
        case .contextualMenuForContainer: context = .container
        case .contextualMenuForSidebar: context = .sidebar
        default: return nil // No toolbar action, and no invented directory.
        }
        let controller = FIFinderSyncController.default()
        let target = FinderMenuTarget.resolve(
            context: context,
            targetedURL: controller.targetedURL(),
            selectedItemURLs: controller.selectedItemURLs()
        )
        let pref = storage.load()
        let menu = NSMenu(title: "LiteRight")
        for preference in pref.orderedMenuItems where preference.isVisible {
            let id = preference.id
            let title: String = id == .openInTerminal ? "在 \(pref.preferredTerminal.title) 中打开" : id.title
            let item = NSMenuItem(title: title, action: #selector(performAction(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = ActionPayload(id: id, target: target)
            item.isEnabled = id == .toggleHiddenFiles || target.directoryURL != nil
            menu.addItem(item)
        }
        return menu.items.isEmpty ? nil : menu
    }
    @objc private func performAction(_ sender: NSMenuItem) {
        guard let payload = sender.representedObject as? ActionPayload else { return }
        do {
            switch payload.id {
            case .newText, .newMarkdown:
                guard let url = payload.target.directoryURL else { return }
                _ = try AtomicFileCreator.createFile(in: url, template: payload.id == .newText ? .text : .markdown)
            case .copyDirectoryPath:
                guard let url = payload.target.directoryURL else { return }
                NSPasteboard.general.clearContents()
                guard NSPasteboard.general.setString(url.path, forType: .string) else { throw LiteRightError.operationFailed("无法复制目录路径。") }
            case .openInTerminal, .toggleHiddenFiles:
                let pref = storage.load()
                let request = OperationRequest(action: payload.id, directoryPath: payload.target.directoryURL?.path, terminalBundleID: pref.preferredTerminal)
                let store = try RequestStore()
                try store.save(request)
                guard let deepLink = URL(string: "lite-right://run?id=\(request.id.uuidString)") else { throw LiteRightError.requestUnavailable }
                NSWorkspace.shared.open(deepLink)
            }
        } catch {
            NSLog("LiteRight action failed: %@", String(describing: error))
            NSSound.beep()
        }
    }
}

private final class ActionPayload: NSObject {
    let id: MenuItemID
    let target: ResolvedTarget
    init(id: MenuItemID, target: ResolvedTarget) { self.id = id; self.target = target }
}
