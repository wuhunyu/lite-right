import AppKit
import SwiftUI
import ApplicationServices
import FinderSync
import LiteRightCore

struct PermissionsView: View {
    @EnvironmentObject private var model: PreferenceViewModel
    @State private var finderExtensionEnabled = false
    @State private var appGroupAvailable = false

    var body: some View {
        Form {
            Section("Finder 扩展") {
                LabeledContent("系统报告状态", value: finderExtensionEnabled ? "已启用（仍需实测右键菜单）" : "未启用或无法确认")
                LabeledContent("主应用 App Group", value: appGroupAvailable ? "共享容器可访问" : "共享容器不可用，请检查签名")
                Button("重新检测扩展状态") { refreshFinderState() }
                Button("打开扩展设置") { FIFinderSyncController.showExtensionManagementInterface() }
                Button("打开系统扩展设置（备用）") { openSettings("x-apple.systempreferences:com.apple.ExtensionsPreferences") }
                Text("系统报告已启用，并不代表 Finder 的右键菜单已通过实机验证。")
                    .font(.caption).foregroundStyle(.secondary)
                Text("菜单只在已登记的监控目录及子目录内出现；可在通用设置中添加目录。")
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
        }
        .formStyle(.grouped).padding(14)
        .onAppear { refreshFinderState() }
    }

    private func refreshFinderState() {
        finderExtensionEnabled = FIFinderSyncController.isExtensionEnabled
        appGroupAvailable = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: SharedPreferences.suiteName
        ) != nil
    }

    private func openSettings(_ path: String) {
        guard let url = URL(string: path) else { return }
        NSWorkspace.shared.open(url)
    }
}
