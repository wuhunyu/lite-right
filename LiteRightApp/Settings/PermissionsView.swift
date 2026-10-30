import AppKit
import CoreGraphics
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
                LabeledContent("主应用 App Group 容器", value: appGroupAvailable ? "可定位（不代表共享偏好可写）" : "不可访问，请检查签名")
                LabeledContent("Finder 设置同步", value: model.sharedSyncWarning == nil ? "尚未验证或上次成功" : "被系统拒绝（本机设置仍可保存）")
                Button("重新检测扩展状态") { refreshFinderState() }
                Button("打开扩展设置") { FIFinderSyncController.showExtensionManagementInterface() }
                Button("打开系统扩展设置（备用）") { openSettings("x-apple.systempreferences:com.apple.ExtensionsPreferences") }
                Text("系统报告已启用、共享容器路径存在，都不代表 Finder 扩展能写入共享偏好或展示右键菜单。")
                    .font(.caption).foregroundStyle(.secondary)
                Text("菜单只在已登记的监控目录及子目录内出现；可在通用设置中添加目录。")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section("终端自动化") {
                LabeledContent("状态", value: "未验证 · 首次使用时由 macOS 请求")
                Button("打开自动化设置") { openSettings("x-apple.systempreferences:com.apple.preference.security?Privacy_Automation") }
            }
            Section("辅助功能") {
                LabeledContent("模拟快捷键", value: CGPreflightPostEventAccess() ? "已授权" : "未授权")
                LabeledContent("切换方式", value: "Finder 原生快捷键（无重启）")
                Button("打开辅助功能授权") { openSettings("x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") }
                Text("显示或隐藏文件时会向 Finder 发送原生 ⌘⇧. 快捷键，不重启 Finder。首次使用需授权 LiteRight 的辅助功能权限；终端自动化授权只用于打开终端。")
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
