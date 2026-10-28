import AppKit
import SwiftUI

struct AboutView: View {
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
            LabeledContent("版本", value: "\(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.1") (\(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"))")
            LabeledContent("系统要求", value: "macOS 27 及更高版本")
            Text("LiteRight 仅在本机运行，不上传、分析或同步你的 Finder 文件内容。所有操作均由用户主动触发。")
                .foregroundStyle(.secondary)
            Button("GitHub 仓库") {
                if let url = URL(string: "https://github.com/wuhunyu/lite-right") { NSWorkspace.shared.open(url) }
            }
            Button("复制诊断摘要") {
                let text = "LiteRight v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.1")\nmacOS \(ProcessInfo.processInfo.operatingSystemVersionString)\n架构 \(ProcessInfo.processInfo.processorCount) CPUs\n原生离线运行"
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(text, forType: .string)
            }
            Spacer()
        }.padding(26).frame(maxWidth: .infinity, alignment: .leading)
    }
}
