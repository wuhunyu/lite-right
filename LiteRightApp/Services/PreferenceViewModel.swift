import Foundation
import SwiftUI
import LiteRightCore

@MainActor
final class PreferenceViewModel: ObservableObject {
    @Published private(set) var value: GeneralPreferences
    @Published var lastError: String?
    private let storage = SharedPreferences()
    init() { value = storage.load() }

    func update(_ change: (inout GeneralPreferences) -> Void) {
        var updated = value
        change(&updated)
        updated = updated.normalized()
        let monitoredRootsChanged = updated.monitoredFolderPaths != value.monitoredFolderPaths
        do {
            try storage.save(updated)
            value = updated
            if monitoredRootsChanged { refreshMonitoredDirectories() }
        } catch { lastError = error.localizedDescription }
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
