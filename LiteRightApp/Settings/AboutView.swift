import AppKit
import SwiftUI
import FinderSync
import LiteRightCore

struct AboutView: View {
    @EnvironmentObject private var model: PreferenceViewModel

    private var displayedVersion: String {
        ReleaseInfo.displayVersion(
            marketingVersion: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0",
            channel: Bundle.main.object(forInfoDictionaryKey: "LiteRightReleaseChannel") as? String ?? "release"
        )
    }

    private var build: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
    }

    private var architecture: String {
        #if arch(arm64)
        return "arm64"
        #elseif arch(x86_64)
        return "x86_64"
        #else
        return "未知"
        #endif
    }

    private var transport: String {
        #if DEBUG || LITERIGHT_UNTRUSTED_PREVIEW
        return "Preview IPC"
        #else
        return "App Group"
        #endif
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 16) {
                Image(nsImage: NSApplication.shared.applicationIconImage)
                    .resizable().frame(width: 68, height: 68)
                VStack(alignment: .leading) {
                    Text("LiteRight").font(.largeTitle.bold())
                    Text("原生、轻量的 Finder 右键工具").foregroundStyle(.secondary)
                }
            }
            LabeledContent("版本", value: "\(displayedVersion) (\(build))")
            LabeledContent("系统要求", value: "macOS 27 及更高版本")
            Text("LiteRight 仅在本机运行，不上传、分析或同步你的 Finder 文件内容。所有操作均由用户主动触发。")
                .foregroundStyle(.secondary)
            Button("GitHub 仓库") {
                if let url = URL(string: "https://github.com/wuhunyu/lite-right") { NSWorkspace.shared.open(url) }
            }
            Button("复制诊断信息") {
                let text = ReleaseInfo.diagnosticSummary(
                    displayedVersion: displayedVersion,
                    build: build,
                    operatingSystem: "macOS \(ProcessInfo.processInfo.operatingSystemVersionString)",
                    architecture: architecture,
                    finderExtensionEnabled: FIFinderSyncController.isExtensionEnabled,
                    transport: transport,
                    monitoredFolderCount: model.value.monitoredFolderPaths.count
                )
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(text, forType: .string)
            }
            Spacer()
        }.padding(26).frame(maxWidth: .infinity, alignment: .leading)
    }
}
