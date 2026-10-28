import AppKit
import SwiftUI
import ApplicationServices

struct PermissionsView: View {
    @EnvironmentObject private var model: PreferenceViewModel

    var body: some View {
        Form {
            Section("Finder 扩展") {
                LabeledContent("状态", value: "请在系统设置中确认（无法可靠自动读取）")
                Button("打开扩展设置") { openSettings("x-apple.systempreferences:com.apple.ExtensionsPreferences") }
                Text("菜单可用范围受到 Finder Sync 监控目录和系统规则限制。")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section("终端自动化") {
                LabeledContent("状态", value: "未验证 · 首次使用时由 macOS 请求")
                Button("打开自动化设置") { openSettings("x-apple.systempreferences:com.apple.preference.security?Privacy_Automation") }
            }
            Section("辅助功能") {
                LabeledContent("状态", value: AXIsProcessTrusted() ? "已授权" : "未授权")
                Toggle("使用 Finder 快捷键切换隐藏文件", isOn: Binding(
                    get: { model.value.useAccessibilityToggleForHiddenFiles },
                    set: { v in model.update { $0.useAccessibilityToggleForHiddenFiles = v } }
                ))
                Button("打开辅助功能授权") { openSettings("x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") }
                Text("默认方式使用 Finder 偏好设置，只有确认后才会重新启动 Finder。")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }.formStyle(.grouped).padding(14)
    }
    private func openSettings(_ path: String) {
        guard let url = URL(string: path) else { return }
        NSWorkspace.shared.open(url)
    }
}
