import SwiftUI

struct SettingsRootView: View {
    @EnvironmentObject private var model: PreferenceViewModel
    @State private var selected: Page = .menu

    private enum Page: String, CaseIterable, Identifiable {
        case menu = "右键菜单", terminal = "终端", general = "通用", permissions = "权限管理", about = "关于"
        var id: Self { self }
        var symbol: String {
            switch self {
            case .menu: "list.bullet.rectangle"
            case .terminal: "terminal"
            case .general: "gearshape"
            case .permissions: "hand.raised"
            case .about: "info.circle"
            }
        }
    }

    var body: some View {
        NavigationSplitView {
            List(Page.allCases, selection: $selected) { page in
                Label(page.rawValue, systemImage: page.symbol).tag(page)
            }
            .navigationSplitViewColumnWidth(min: 176, ideal: 190, max: 220)
            .listStyle(.sidebar)
        } detail: {
            Group {
                switch selected {
                case .menu: MenuSettingsView()
                case .terminal: TerminalSettingsView()
                case .general: GeneralSettingsView()
                case .permissions: PermissionsView()
                case .about: AboutView()
                }
            }
            .environmentObject(model)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if let warning = model.sharedSyncWarning {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text(warning)
                        .font(.caption)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.regularMaterial)
            }
        }
        .alert("无法保存配置", isPresented: Binding(get: { model.lastError != nil }, set: { if !$0 { model.lastError = nil } })) {
            Button("确定") { model.lastError = nil }
        } message: { Text(model.lastError ?? "") }
    }
}
