import AppKit
import SwiftUI
import LiteRightCore

@MainActor
final class LiteRightApplicationDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // LSUIElement already establishes accessory mode. Avoid changing activation
        // policy while SwiftUI is constructing its initial scene graph.
        let desired: NSApplication.ActivationPolicy = SharedPreferences().load().showDockIcon ? .regular : .accessory
        guard NSApp.activationPolicy() != desired else { return }
        DispatchQueue.main.async {
            if NSApp.activationPolicy() != desired { NSApp.setActivationPolicy(desired) }
        }
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

    var body: some Scene {
        Window("LiteRight 设置", id: "preferences") {
            SettingsRootView()
                .environmentObject(model)
                .frame(minWidth: 640, minHeight: 420)
                .onOpenURL { url in Task { await dispatcher.handleIncomingURL(url) } }
                .onChange(of: model.value.showDockIcon) { _, visible in
                    NSApp.setActivationPolicy(visible ? .regular : .accessory)
                }
        }
        .defaultSize(width: 760, height: 520)
        .commands { CommandGroup(replacing: .newItem) {} }

        MenuBarExtra("LiteRight", systemImage: "cursorarrow.click.2", isInserted: model.menuBarVisible) {
            MenuBarActions()
        }
    }
}

struct MenuBarActions: View {
    @Environment(\.openWindow) private var openWindow
    var body: some View {
        Button("打开 LiteRight 设置") {
            openWindow(id: "preferences")
            NSApp.activate(ignoringOtherApps: true)
        }
        Button("退出 LiteRight") { NSApp.terminate(nil) }
    }
}
