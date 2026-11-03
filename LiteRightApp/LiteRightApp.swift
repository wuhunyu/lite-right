import AppKit
import Combine
import SwiftUI
import LiteRightCore

/// Finder requests must be handled by the application delegate, not a
/// SwiftUI Window scene. The host stays headless until Settings are requested.
@MainActor
final class LiteRightApplicationDelegate: NSObject, NSApplicationDelegate {
    let model: PreferenceViewModel

    private let statusBar = StatusBarController()
    private let dispatcher = OperationDispatcher()
    private var preferencesWindow: NSWindow?
    private var preferencesObservation: AnyCancellable?
    // An app open should show Settings. A Finder custom URL should not.
    // LaunchServices may deliver open-URL after didFinishLaunching or reopen,
    // so use a cancellable, short deferred presentation for ambiguous events.
    private var pendingSettingsPresentation: Task<Void, Never>?
    private var launchIntent = LaunchIntentCoordinator()

    override init() {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        let preferencesPath = arguments.first(where: {
            $0.hasPrefix("--literight-probe-preferences-path=")
        }).map { String($0.dropFirst("--literight-probe-preferences-path=".count)) }
        model = PreferenceViewModel(preferencesURL: preferencesPath.map(URL.init(fileURLWithPath:)))
        #else
        model = PreferenceViewModel()
        #endif
        super.init()
    }

    #if DEBUG || LITERIGHT_UNTRUSTED_PREVIEW
    private func sendPreviewMenuSnapshot() {
        guard let prefs = try? HostPreferencesStore().load(),
              let encoded = PreviewMenuSync.encode(prefs) else { return }
        DistributedNotificationCenter.default().post(
            name: PreviewMenuSync.snapshotName, object: encoded
        )
    }

    @objc private func onPreviewSettingsRequest(_ note: Notification) {
        sendPreviewMenuSnapshot()
    }
    #endif

    func applicationDidFinishLaunching(_ notification: Notification) {
        #if DEBUG || LITERIGHT_UNTRUSTED_PREVIEW
        DistributedNotificationCenter.default().addObserver(
            self, selector: #selector(onPreviewSettingsRequest(_:)),
            name: PreviewMenuSync.requestName, object: nil
        )
        sendPreviewMenuSnapshot()
        #endif

        statusBar.onOpenPreferences = { [weak self] in self?.openPreferences() }
        applyDisplayPreferences(model.value)
        // The SwiftUI settings view is no longer mounted during background work.
        // Observe the shared model here so toggles still update Dock/menu icons.
        preferencesObservation = model.$value.dropFirst().sink { [weak self] preferences in
            self?.applyDisplayPreferences(preferences)
        }

        #if DEBUG
        // UI probes may request a deterministic Settings window or an
        // intentionally headless host for Finder URL regression tests.
        if ProcessInfo.processInfo.arguments.contains("--literight-probe-show-settings") {
            openPreferences()
            return
        }
        if ProcessInfo.processInfo.arguments.contains("--literight-probe-start-headless") {
            return
        }
        #endif

        // Ordinary Finder/Spotlight launches must open Settings, even when
        // both Dock and menu-bar icons are hidden. A cold lite-right://run
        // delivery cancels this before it can present a window.
        scheduleSettingsPresentation(after: .milliseconds(850), coldLaunch: true)
    }

    /// AppKit delivers both warm and cold custom-URL launches here.
    /// No settings window is created just to receive a Finder action.
    func application(_ application: NSApplication, open urls: [URL]) {
        // Incoming operations are never implicit requests to show Settings.
        // Cancel any pending window from application launch/reopen first.
        if !urls.isEmpty {
            launchIntent.recordOperationURL()
            pendingSettingsPresentation?.cancel()
            pendingSettingsPresentation = nil
        }
        for url in urls {
            Task { await dispatcher.handleIncomingURL(url) }
        }
    }

    deinit {
        #if DEBUG || LITERIGHT_UNTRUSTED_PREVIEW
        DistributedNotificationCenter.default().removeObserver(self)
        #endif
    }

    private func applyDisplayPreferences(_ preferences: GeneralPreferences) {
        NSApp.setActivationPolicy(preferences.showDockIcon ? .regular : .accessory)
        setMenuBarVisible(preferences.showMenuBarIcon)
    }

    func setMenuBarVisible(_ visible: Bool) {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--literight-probe-no-menubar") {
            statusBar.setVisible(false)
            return
        }
        #endif
        statusBar.setVisible(visible)
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool {
        // Double-clicking a running LiteRight.app is a user-facing Settings
        // request. URL-based Finder operations can also involve LaunchServices,
        // so the short delay lets their dedicated open-URL event cancel it.
        scheduleSettingsPresentation(after: .milliseconds(450), coldLaunch: false)
        return false
    }

    private func scheduleSettingsPresentation(after delay: Duration, coldLaunch: Bool) {
        pendingSettingsPresentation?.cancel()
        pendingSettingsPresentation = Task { @MainActor [weak self] in
            try? await Task.sleep(for: delay)
            guard !Task.isCancelled, let self else { return }
            guard self.launchIntent.shouldPresentSettings(afterColdLaunch: coldLaunch) else { return }
            self.openPreferences()
        }
    }

    /// Dock context menus are an explicit way to open Settings without using
    /// the implicit reopen callback (which is also triggered by URL delivery).
    func applicationDockMenu(_ sender: NSApplication) -> NSMenu? {
        let menu = NSMenu(title: "LiteRight")
        let item = NSMenuItem(title: "打开 LiteRight 设置",
                              action: #selector(openPreferencesFromDock(_:)),
                              keyEquivalent: "")
        item.target = self
        menu.addItem(item)
        return menu
    }

    @objc private func openPreferencesFromDock(_ sender: Any?) {
        openPreferences()
    }

    func openPreferences() {
        let window: NSWindow
        if let existing = preferencesWindow {
            window = existing
        } else {
            let content: AnyView
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("--literight-probe-minimal-window") {
                content = AnyView(Text("LiteRight Startup Probe"))
            } else {
                content = AnyView(SettingsRootView().environmentObject(model))
            }
            #else
            content = AnyView(SettingsRootView().environmentObject(model))
            #endif

            let created = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 760, height: 520),
                styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )
            created.title = "LiteRight"
            // A full-size content view lets the sidebar material extend
            // underneath the traffic-light region. The toolbar reserves the
            // titlebar safe area for the SwiftUI navigation/detail content.
            created.titleVisibility = .visible
            created.titlebarAppearsTransparent = true
            created.titlebarSeparatorStyle = .none
            created.toolbarStyle = .unified
            let toolbar = NSToolbar(identifier: "LiteRightSettingsToolbar")
            toolbar.allowsUserCustomization = false
            created.toolbar = toolbar
            created.contentViewController = NSHostingController(
                rootView: content.frame(minWidth: 640, minHeight: 420)
            )
            created.isReleasedWhenClosed = false
            created.center()
            if let visibleFrame = (created.screen ?? NSScreen.main)?.visibleFrame {
                var frame = created.frame
                frame.origin.x = min(max(frame.origin.x, visibleFrame.minX),
                                     max(visibleFrame.minX, visibleFrame.maxX - frame.width))
                frame.origin.y = min(max(frame.origin.y, visibleFrame.minY),
                                     max(visibleFrame.minY, visibleFrame.maxY - frame.height))
                created.setFrame(frame, display: false)
            }
            preferencesWindow = created
            window = created
        }

        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }
}

@main
struct LiteRightApp: App {
    @NSApplicationDelegateAdaptor(LiteRightApplicationDelegate.self) private var appDelegate

    var body: some Scene {
        // A Settings scene never needs to be instantiated to deliver Finder URLs.
        // Keep the host headless on both cold and warm lite-right://run launches.
        // Explicit user requests are handled by the AppKit preferences window.
        Settings {
            SettingsRootView()
                .environmentObject(appDelegate.model)
                .frame(minWidth: 640, minHeight: 420)
        }
    }
}
