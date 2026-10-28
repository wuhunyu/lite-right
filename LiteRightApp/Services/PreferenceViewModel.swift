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
        do { try storage.save(updated); value = updated }
        catch { lastError = error.localizedDescription }
    }
    func resetMenus() { update { $0.orderedMenuItems = GeneralPreferences.default.orderedMenuItems } }
    func moveMenu(from offsets: IndexSet, to destination: Int) {
        update { $0.orderedMenuItems.move(fromOffsets: offsets, toOffset: destination) }
    }
    var menuBarVisible: Binding<Bool> {
        Binding(get: { self.value.showMenuBarIcon }, set: { new in self.update { $0.showMenuBarIcon = new } })
    }
}
