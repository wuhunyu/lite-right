import AppKit
import Combine
import SwiftUI
import LiteRightCore

/// Finder requests must be handled by the application delegate, not a
/// SwiftUI Window scene. The host stays headless until Settings are requested.
@MainActor
final class LiteRightApplicationDelegate: NSObject, NSApplicationDelegate {
    let model = PreferenceViewModel()

    private let statusBar = StatusBarController()
    private let dispatcher = OperationDispatcher()
    private var preferencesWindow: NSWindow?
    private var preferencesObservation: AnyCancellable?

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
        // XCUITest requests a settings window explicitly; real URL launches
        // never carry this flag and are intentionally silent.
        if ProcessInfo.processInfo.arguments.contains("--literight-probe-show-settings") {
            openPreferences()
        }
        #endif
    }

    /// AppKit delivers both warm and cold custom-URL launches here.
    /// No settings window is created just to receive a Finder action.
    func application(_ application: NSApplication, open urls: [URL]) {
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
        // Dock relaunch is an explicit request for Settings, unlike open URLs.
        openPreferences()
        return true
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
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false
            )
            created.title = "LiteRight 设置"
            created.contentViewController = NSHostingController(
                rootView: content.frame(minWidth: 640, minHeight: 420)
            )
            created.isReleasedWhenClosed = false
            created.center()
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
        Window("LiteRight 设置", id: "preferences") {
            SettingsRootView().environmentObject(appDelegate.model)
                .frame(minWidth: 640, minHeight: 420)
        }
        // No scene on login/startup, and opening a custom URL must not
        // auto-create or restore this window.
        .defaultLaunchBehavior(.suppressed)
        .restorationBehavior(.disabled)
        .defaultSize(width: 760, height: 520)
        .commands { CommandGroup(replacing: .newItem) {} }
    }
}
