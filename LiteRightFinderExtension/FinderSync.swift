import Cocoa
import FinderSync
import LiteRightCore
import os

final class FinderSync: FIFinderSync {
    private let storage = SharedPreferences()
    #if DEBUG || LITERIGHT_UNTRUSTED_PREVIEW
    private var previewPreferences: GeneralPreferences?
    #endif

    private func currentPreferences() -> GeneralPreferences {
        #if DEBUG || LITERIGHT_UNTRUSTED_PREVIEW
        if let previewPreferences { return previewPreferences }
        #endif
        return storage.load()
    }
    private let logger = Logger(subsystem: "com.wuhunyu.literight.finder", category: "lifecycle")
    override init() {
        super.init()
        logger.notice("finder_sync_init process=\(ProcessInfo.processInfo.processIdentifier)")
        #if DEBUG || LITERIGHT_UNTRUSTED_PREVIEW
        DistributedNotificationCenter.default().addObserver(
            self, selector: #selector(receivePreviewPreferences(_:)),
            name: PreviewMenuSync.snapshotName, object: nil
        )
        DistributedNotificationCenter.default().post(
            name: PreviewMenuSync.requestName, object: nil
        )
        #endif
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

    #if DEBUG || LITERIGHT_UNTRUSTED_PREVIEW
    @objc private func receivePreviewPreferences(_ notification: Notification) {
        guard let preferences = PreviewMenuSync.decode(notification.object as? String) else {
            logger.error("preview_settings_invalid")
            return
        }
        previewPreferences = preferences
        logger.notice("preview_settings_received visible_count=\(preferences.orderedMenuItems.filter(\\.isVisible).count)")
        reloadMonitoredDirectories()
    }
    #endif

    private func reloadMonitoredDirectories() {
        let preferences = currentPreferences()
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
        let pref = currentPreferences()
        logger.notice("menu_callback kind=\(menuKind.rawValue) selection=\(controller.selectedItemURLs()?.count ?? 0) target_available=\(target.directoryURL != nil) visible_count=\(pref.orderedMenuItems.filter(\.isVisible).count)")
        let menu = NSMenu(title: "LiteRight")
        for preference in pref.orderedMenuItems where preference.isVisible {
            let id = preference.id
            let hiddenPresentation = FinderHiddenFilesState.menuPresentation(
                showing: FinderHiddenFilesState.isShowingHiddenFiles()
            )
            let title: String = id == .openInTerminal
                ? "在 \(pref.preferredTerminal.title) 打开"
                : (id == .toggleHiddenFiles ? hiddenPresentation.title : id.title)
            let item = NSMenuItem(title: title, action: #selector(performAction(_:)), keyEquivalent: "")
            item.target = self
            if let symbol = NSImage(systemSymbolName: id == .toggleHiddenFiles ? hiddenPresentation.symbol : id.symbol, accessibilityDescription: title) {
                symbol.isTemplate = true
                item.image = symbol
            }
            // Finder copies the menu item; representedObject and target
            // are not preserved. The integer tag survives the copy.
            guard let actionTag = FinderActionTag.tag(for: id, context: context) else { continue }
            item.tag = actionTag
            item.isEnabled = id == .toggleHiddenFiles || target.directoryURL != nil
            menu.addItem(item)
        }
        logger.notice("menu_result item_count=\(menu.items.count)")
        return menu.items.isEmpty ? nil : menu
    }
    @objc private func performAction(_ sender: NSMenuItem) {
        guard let selection = FinderActionTag.resolve(tag: sender.tag) else {
            logger.error("finder_action_failed invalid_menu_tag=\(sender.tag)")
            NSSound.beep()
            return
        }

        // Query Finder's current target at action time. Finder's replicated
        // NSMenuItem cannot retain arbitrary per-item objects.
        let controller = FIFinderSyncController.default()
        let target = FinderMenuTarget.resolve(
            context: selection.context,
            targetedURL: controller.targetedURL(),
            selectedItemURLs: controller.selectedItemURLs()
        )
        logger.notice("finder_action_selected action=\(selection.action.rawValue, privacy: .public) target_available=\(target.directoryURL != nil)")
        guard selection.action == .toggleHiddenFiles || target.directoryURL != nil else {
            logger.error("finder_action_failed target_unavailable")
            NSSound.beep()
            return
        }

        do {
            let pref = currentPreferences()
            let request = OperationRequest.forFinderMenu(
                action: selection.action,
                directoryURL: target.directoryURL,
                preferredTerminal: pref.preferredTerminal
            )

            #if DEBUG || LITERIGHT_UNTRUSTED_PREVIEW
            // An ad-hoc build cannot rely on a Team-authorized App Group.
            // Validate this local, untrusted link again in the host.
            let deepLink = try PreviewRequestLink.encode(request)
            logger.notice("finder_action_transport preview_link")
            #else
            let store = try RequestStore()
            try store.save(request)
            guard let deepLink = URL(string: "lite-right://run?id=\(request.id.uuidString)") else {
                throw LiteRightError.requestUnavailable
            }
            logger.notice("finder_action_transport app_group")
            #endif

            guard NSWorkspace.shared.open(deepLink) else {
                throw LiteRightError.operationFailed("无法启动 LiteRight 主应用。请确认应用已安装且 URL Scheme 已注册。")
            }
            logger.notice("finder_action_opened action=\(selection.action.rawValue, privacy: .public)")
        } catch {
            logger.error("finder_action_failed action=\(selection.action.rawValue, privacy: .public) error=\(String(describing: error), privacy: .private)")
            NSLog("LiteRight Finder action failed: %@", String(describing: error))
            NSSound.beep()
        }
    }
}