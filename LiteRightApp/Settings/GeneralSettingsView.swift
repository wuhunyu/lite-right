import AppKit
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
                Text("Finder Sync 只在已配置目录及其子目录内提供右键菜单。默认监控用户主目录，外接磁盘与网络共享可单独添加。")
                    .font(.caption).foregroundStyle(.secondary)
                ForEach(model.value.monitoredFolderPaths, id: \.self) { path in
                    HStack(spacing: 10) {
                        Image(systemName: "folder")
                            .foregroundStyle(.secondary)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(path)
                                .lineLimit(1)
                                .truncationMode(.middle)
                                .help(path)
                            Text(isAccessible(path) ? "当前目录可访问" : "当前不可访问，重新连接后请刷新")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 8)
                        Button("移除") {
                            model.update { $0.monitoredFolderPaths.removeAll(where: { $0 == path }) }
                        }
                        .buttonStyle(.borderless)
                    }
                }
                HStack {
                    Button("添加监控目录", systemImage: "plus") { chooseDirectories() }
                    Button("刷新监控目录", systemImage: "arrow.clockwise") {
                        model.refreshMonitoredDirectories()
                    }
                }
                Text("变更将通知已运行的 Finder 扩展；若菜单仍未显示，请确认系统设置中已启用扩展。Finder 的菜单层级与位置由系统决定。")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding(14)
        .onAppear { login.refresh() }
        .alert("设置失败", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("确定") { errorMessage = nil }
        } message: { Text(errorMessage ?? "") }
    }

    private func isAccessible(_ path: String) -> Bool {
        TargetResolver.validatedDirectory(URL(fileURLWithPath: path, isDirectory: true)) != nil
    }

    private func chooseDirectories() {
        let panel = NSOpenPanel()
        panel.message = "选择需要 LiteRight 显示右键菜单的 Finder 目录"
        panel.prompt = "添加监控目录"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        panel.canCreateDirectories = false
        panel.begin { response in
            guard response == .OK else { return }
            let paths = panel.urls.map(\.path)
            Task { @MainActor in
                model.update { $0.monitoredFolderPaths.append(contentsOf: paths) }
            }
        }
    }
}
