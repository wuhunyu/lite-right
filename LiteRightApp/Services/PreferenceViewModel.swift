import Foundation
import SwiftUI
import LiteRightCore

@MainActor
final class PreferenceViewModel: ObservableObject {
    @Published private(set) var value: GeneralPreferences
    @Published var lastError: String?
    @Published private(set) var sharedSyncWarning: String?
    private let storage = HostPreferencesStore()
    private let sharedStorage = SharedPreferences()

    init() {
        do {
            value = try storage.load()
        } catch {
            value = .default
            lastError = "无法读取已保存的本机设置：\(error.localizedDescription)"
        }
    }

    func update(_ change: (inout GeneralPreferences) -> Void) {
        var updated = value
        change(&updated)
        updated = updated.normalized()
        let monitoredRootsChanged = updated.monitoredFolderPaths != value.monitoredFolderPaths
        do {
            // Commit canonical user settings independently of App Group privileges.
            // Never roll back a successful local write because Finder sharing is denied.
            try storage.save(updated)
            value = updated
            do {
                try sharedStorage.save(updated)
                sharedSyncWarning = nil
                if monitoredRootsChanged { refreshMonitoredDirectories() }
            } catch {
                sharedSyncWarning = "设置已保存在本机，但 Finder 扩展共享配置同步失败：\(error.localizedDescription)"
            }
        } catch {
            lastError = error.localizedDescription
        }
    }

    func refreshMonitoredDirectories() {
        // Only a signal is sent; the extension reloads paths from its shared suite.
        DistributedNotificationCenter.default().postNotificationName(
            Notification.Name(MonitoredFolders.didChangeNotification),
            object: nil, userInfo: nil, deliverImmediately: true
        )
    }

    func resetMenus() { update { $0.orderedMenuItems = GeneralPreferences.default.orderedMenuItems } }
    func moveMenu(from offsets: IndexSet, to destination: Int) {
        update { $0.orderedMenuItems.move(fromOffsets: offsets, toOffset: destination) }
    }
    var menuBarVisible: Binding<Bool> {
        Binding(get: { self.value.showMenuBarIcon }, set: { new in self.update { $0.showMenuBarIcon = new } })
    }
}
