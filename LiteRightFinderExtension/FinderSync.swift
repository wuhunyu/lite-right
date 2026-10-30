import Cocoa
import FinderSync
import LiteRightCore
import os

final class FinderSync: FIFinderSync {
    private let storage = SharedPreferences()
    private let logger = Logger(subsystem: "com.wuhunyu.literight.finder", category: "lifecycle")
    override init() {
        super.init()
        logger.notice("finder_sync_init process=\(ProcessInfo.processInfo.processIdentifier)")
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
        let preferences = storage.load()
        let paths = preferences.monitoredFolderPaths
        let urls = MonitoredFolders.registrationDirectoryURLs(paths)
        FIFinderSyncController.default().directoryURLs = urls
        let loginHome = UserHomeDirectory.current()
        let homeURL = URL(fileURLWithPath: loginHome.isEmpty ? "/__unknown_home__" : loginHome, isDirectory: true)
        let testURL = homeURL.appendingPathComponent("LiteRightLocalTest", isDirectory: true)
        let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: SharedPreferences.suiteName)
        let foundationHome = FileManager.default.homeDirectory(forUser: NSUserName())?.standardizedFileURL.path
        let foundationHomeDiffers = foundationHome != nil && foundationHome != loginHome
        logger.notice("watch_registration roots=\(urls.count) posix_home_available=\(!loginHome.isEmpty) foundation_home_differs=\(foundationHomeDiffers) home_covered=\(MonitoredFolders.covers(homeURL, registeredRoots: urls)) test_covered=\(MonitoredFolders.covers(testURL, registeredRoots: urls)) group_container_available=\(groupURL != nil)")
        // Paths stay private: only report whether the POSIX login home matches
        // the Foundation sandbox home and whether actual monitored roots cover it.
    }

    override func beginObservingDirectory(at url: URL) {
        logger.notice("begin_observing monitored=\(MonitoredFolders.covers(url, registeredRoots: FIFinderSyncController.default().directoryURLs))")
    }

    override func endObservingDirectory(at url: URL) {
        logger.notice("end_observing")
    }

    override func menu(for menuKind: FIMenuKind) -> NSMenu? {
        let context: FinderMenuContext
        switch menuKind {
        case .contextualMenuForItems: context = .items
        case .contextualMenuForContainer: context = .container
        case .contextualMenuForSidebar: context = .sidebar
        default:
            logger.notice("menu_unsupported_context kind=\(menuKind.rawValue)")
            return nil // No toolbar action, and no invented directory.
        }
        let controller = FIFinderSyncController.default()
        let target = FinderMenuTarget.resolve(
            context: context,
            targetedURL: controller.targetedURL(),
            selectedItemURLs: controller.selectedItemURLs()
        )
        let pref = storage.load()
        logger.notice("menu_callback kind=\(menuKind.rawValue) selection=\(controller.selectedItemURLs()?.count ?? 0) target_available=\(target.directoryURL != nil) visible_count=\(pref.orderedMenuItems.filter(\.isVisible).count)")
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
        logger.notice("menu_result item_count=\(menu.items.count)")
        return menu.items.isEmpty ? nil : menu
    }
    @objc private func performAction(_ sender: NSMenuItem) {
        guard let payload = sender.representedObject as? ActionPayload else { return }
        do {
            // FinderSync is sandboxed. Never create files or rely on user-file
            // permissions here; route the action to the native host instead.
            let pref = storage.load()
            let request = OperationRequest(
                action: payload.id,
                directoryPath: payload.target.directoryURL?.path,
                terminalBundleID: pref.preferredTerminal
            )
            let store = try RequestStore()
            try store.save(request)
            guard let deepLink = URL(string: "lite-right://run?id=\(request.id.uuidString)") else {
                throw LiteRightError.requestUnavailable
            }
            guard NSWorkspace.shared.open(deepLink) else {
                throw LiteRightError.operationFailed("无法启动 LiteRight 主应用。请从应用程序目录打开 LiteRight 后重试。")
            }
        } catch {
            NSLog("LiteRight Finder action failed: %@", String(describing: error))
            NSSound.beep()
        }
    }
}

private final class ActionPayload: NSObject {
    let id: MenuItemID
    let target: ResolvedTarget
    init(id: MenuItemID, target: ResolvedTarget) { self.id = id; self.target = target }
}
