import SwiftUI
import LiteRightCore

struct GeneralSettingsView: View {
    @EnvironmentObject private var model: PreferenceViewModel
    @StateObject private var login = LoginItemController()
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Section("外观") {
                Toggle("显示菜单栏图标", isOn: Binding(get: { model.value.showMenuBarIcon }, set: { v in model.update { $0.showMenuBarIcon = v } }))
                Toggle("显示 Dock 图标", isOn: Binding(get: { model.value.showDockIcon }, set: { v in model.update { $0.showDockIcon = v } }))
                Text("如果隐藏两个图标，仍可从 Spotlight 或应用程序文件夹打开 LiteRight。")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section("登录") {
                Toggle("登录时自动启动", isOn: Binding(
                    get: { login.isEnabled },
                    set: { selected in do { try login.setEnabled(selected) } catch { errorMessage = error.localizedDescription } }
                ))
                Text("使用 macOS 的登录项管理，不会添加 LaunchAgent。")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section("Finder 监控") {
                Text("目前默认监控用户主目录。外接磁盘与网络共享需独立完成 Finder 兼容性验证。")
                    .font(.subheadline)
            }
        }.formStyle(.grouped)
            .padding(14)
            .onAppear { login.refresh() }
            .alert("设置失败", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
                Button("确定") { errorMessage = nil }
            } message: { Text(errorMessage ?? "") }
    }
}
