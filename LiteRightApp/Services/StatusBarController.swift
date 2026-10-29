import AppKit

/// Native AppKit status item avoids a SwiftUI MenuBarExtra/Window scene-update
/// recursion observed on macOS 27 in hosted XCUITest.
@MainActor
final class StatusBarController: NSObject {
    private var statusItem: NSStatusItem?

    func setVisible(_ visible: Bool) {
        if !visible {
            if let statusItem {
                NSStatusBar.system.removeStatusItem(statusItem)
                self.statusItem = nil
            }
            return
        }
        guard statusItem == nil else { return }

        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        let image = NSImage(systemSymbolName: "cursorarrow.click.2", accessibilityDescription: "LiteRight")
        image?.isTemplate = true
        item.button?.image = image
        item.button?.toolTip = "LiteRight"

        let menu = NSMenu(title: "LiteRight")
        let preferences = NSMenuItem(title: "打开 LiteRight 设置",
                                     action: #selector(openPreferences(_:)), keyEquivalent: "")
        preferences.target = self
        menu.addItem(preferences)
        menu.addItem(.separator())

        let quit = NSMenuItem(title: "退出 LiteRight",
                              action: #selector(quitApplication(_:)), keyEquivalent: "")
        quit.target = self
        menu.addItem(quit)
        item.menu = menu
        statusItem = item
    }

    @objc private func openPreferences(_ sender: Any?) {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.windows.first(where: { $0.canBecomeKey })?.makeKeyAndOrderFront(nil)
    }

    @objc private func quitApplication(_ sender: Any?) {
        NSApp.terminate(nil)
    }
}
