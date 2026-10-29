import AppKit
import SwiftUI
import LiteRightCore

@MainActor
final class LiteRightApplicationDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(SharedPreferences().load().showDockIcon ? .regular : .accessory)
    }
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.windows.first(where: { $0.canBecomeKey })?.makeKeyAndOrderFront(nil)
        return true
    }
}

@main
struct LiteRightApp: App {
    @NSApplicationDelegateAdaptor(LiteRightApplicationDelegate.self) private var appDelegate
    @StateObject private var model = PreferenceViewModel()
    @StateObject private var dispatcher = OperationDispatcher()

    #if DEBUG
    // Diagnostic flags are accepted only in debug builds and never affect releases.
    private var probeMinimalWindow: Bool {
        ProcessInfo.processInfo.arguments.contains("--literight-probe-minimal-window")
    }
    private var probeNoMenuBar: Bool {
        ProcessInfo.processInfo.arguments.contains("--literight-probe-no-menubar")
    }
    #endif

    var body: some Scene {
        Window("LiteRight 设置", id: "preferences") {
            #if DEBUG
            if probeMinimalWindow {
                Text("LiteRight Startup Probe")
            } else {
                SettingsRootView().environmentObject(model)
            }
            #else
            SettingsRootView().environmentObject(model)
            #endif
                .frame(minWidth: 640, minHeight: 420)
                .onOpenURL { url in Task { await dispatcher.handleIncomingURL(url) } }
                .onChange(of: model.value.showDockIcon) { _, visible in
                    NSApp.setActivationPolicy(visible ? .regular : .accessory)
                }
        }
        .defaultSize(width: 760, height: 520)
        .commands { CommandGroup(replacing: .newItem) {} }

        #if DEBUG
        if !probeNoMenuBar {
            MenuBarExtra("LiteRight", systemImage: "cursorarrow.click.2", isInserted: model.menuBarVisible) {
                MenuBarActions()
            }
        }
        #else
        MenuBarExtra("LiteRight", systemImage: "cursorarrow.click.2", isInserted: model.menuBarVisible) {
            MenuBarActions()
        }
        #endif
    }
}

struct MenuBarActions: View {
    @Environment(\.openWindow) private var openWindow
    var body: some View {
        Button("打开 LiteRight 设置") {
            openWindow(id: "preferences")
            NSApp.activate(ignoringOtherApps: true)
        }
        Divider()
        Button("退出 LiteRight") { NSApp.terminate(nil) }
    }
}
