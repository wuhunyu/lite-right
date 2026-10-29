import AppKit
import SwiftUI
import LiteRightCore

@MainActor
final class LiteRightApplicationDelegate: NSObject, NSApplicationDelegate {
    private let statusBar = StatusBarController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        let preferences = (try? HostPreferencesStore().load()) ?? .default
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
        openPreferences()
        return true
    }

    func openPreferences() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.windows.first(where: { $0.canBecomeKey })?.makeKeyAndOrderFront(nil)
    }
}

@main
struct LiteRightApp: App {
    @NSApplicationDelegateAdaptor(LiteRightApplicationDelegate.self) private var appDelegate
    @StateObject private var model = PreferenceViewModel()
    @StateObject private var dispatcher = OperationDispatcher()

    #if DEBUG
    // Diagnostic flag only affects the XCUITest scene and is absent in release builds.
    private var probeMinimalWindow: Bool {
        ProcessInfo.processInfo.arguments.contains("--literight-probe-minimal-window")
    }
    #endif

    var body: some Scene {
        Window("LiteRight 设置", id: "preferences") {
            Group {
                #if DEBUG
                if probeMinimalWindow {
                    Text("LiteRight Startup Probe")
                } else {
                    SettingsRootView().environmentObject(model)
                }
                #else
                SettingsRootView().environmentObject(model)
                #endif
            }
            .frame(minWidth: 640, minHeight: 420)
            .onOpenURL { url in Task { await dispatcher.handleIncomingURL(url) } }
            .onChange(of: model.value.showDockIcon) { _, visible in
                NSApp.setActivationPolicy(visible ? .regular : .accessory)
            }
            .onChange(of: model.value.showMenuBarIcon) { _, visible in
                appDelegate.setMenuBarVisible(visible)
            }
        }
        .defaultSize(width: 760, height: 520)
        .commands { CommandGroup(replacing: .newItem) {} }
    }
}
