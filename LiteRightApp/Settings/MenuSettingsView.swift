import SwiftUI
import LiteRightCore

struct MenuSettingsView: View {
    @EnvironmentObject private var model: PreferenceViewModel
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("右键菜单").font(.title2.bold())
            Text("调整 LiteRight 的五个菜单顺序，或隐藏不常用的操作。下一次右键即生效。")
                .font(.subheadline).foregroundStyle(.secondary)
            List {
                ForEach(model.value.orderedMenuItems) { entry in
                    HStack(spacing: 12) {
                        Image(systemName: "line.3.horizontal")
                            .foregroundStyle(.tertiary).accessibilityHidden(true)
                        Label(entry.id.title, systemImage: entry.id.symbol)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Toggle("显示", isOn: Binding(
                            get: { model.value.orderedMenuItems.first(where: { $0.id == entry.id })?.isVisible ?? true },
                            set: { visible in model.update { prefs in
                                if let i = prefs.orderedMenuItems.firstIndex(where: { $0.id == entry.id }) {
                                    prefs.orderedMenuItems[i].isVisible = visible
                                }
                            }}
                        ))
                        .labelsHidden().accessibilityLabel("显示 \(entry.id.title)")
                    }
                    .padding(.vertical, 5)
                }
                .onMove(perform: model.moveMenu)
            }
            .listStyle(.inset)
            HStack {
                Text("拖动列表项可改变顺序。")
                    .font(.caption).foregroundStyle(.secondary)
                Spacer()
                Button("恢复默认") { model.resetMenus() }
            }
        }
        .padding(26)
    }
}
