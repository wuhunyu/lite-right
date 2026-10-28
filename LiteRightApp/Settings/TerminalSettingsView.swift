import AppKit
import SwiftUI
import LiteRightCore

struct TerminalSettingsView: View {
    @EnvironmentObject private var model: PreferenceViewModel
    @State private var terminalStatuses: [(id: TerminalBundle, available: Bool)] = []
    @State private var shells: [ShellAvailability] = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Text("终端").font(.title2.bold())
                    Spacer()
                    Button("重新检测", systemImage: "arrow.clockwise") { refresh() }
                        .labelStyle(.titleAndIcon)
                }
                Text("终端应用负责显示窗口；Bash、Zsh、Fish 是在窗口中运行的 Shell，二者分别选择。")
                    .font(.subheadline).foregroundStyle(.secondary)
                GroupBox("打开方式") {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(terminalStatuses, id: \.id) { item in
                            choiceRow(title: item.id.title,
                                      selected: model.value.preferredTerminal == item.id,
                                      available: item.available) {
                                model.update { $0.preferredTerminal = item.id }
                            }
                        }
                    }.padding(8)
                }
                GroupBox("Shell 自动检测") {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(shells) { item in
                            choiceRow(title: item.kind.title,
                                      subtitle: item.executablePath ?? (item.kind == .systemDefault ? "继承终端默认登录 Shell" : "未安装 · 不可选"),
                                      selected: model.value.selectedShell == item.kind,
                                      available: item.isAvailable) {
                                model.update { $0.selectedShell = item.kind }
                            }
                        }
                    }.padding(8)
                }
                Toggle("切换目录后清空终端可视内容（clear）", isOn: Binding(
                    get: { model.value.clearAfterCD },
                    set: { v in model.update { $0.clearAfterCD = v } }
                ))
                Text("仅在打开设置和实际执行前检查安装状态；不会持续扫描后台进程。")
                    .font(.caption).foregroundStyle(.tertiary)
            }.padding(26)
        }.onAppear(perform: refresh)
    }

    private func refresh() {
        terminalStatuses = TerminalBundle.allCases.map { item in
            (id: item, available: NSWorkspace.shared.urlForApplication(withBundleIdentifier: item.rawValue) != nil)
        }
        shells = ShellCatalog.detect()
    }

    private func choiceRow(title: String, subtitle: String? = nil, selected: Bool, available: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: selected ? "largecircle.fill.circle" : "circle")
                    .foregroundStyle(selected ? Color.accentColor : .secondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                    if let subtitle { Text(subtitle).font(.caption).foregroundStyle(.secondary) }
                }
                Spacer()
                if !available { Text("不可用").font(.caption).foregroundStyle(.secondary) }
            }.frame(maxWidth: .infinity, alignment: .leading).contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!available)
        .opacity(available ? 1 : 0.48)
        .accessibilityLabel("\(title)，\(available ? "可选择" : "未安装")")
    }
}
