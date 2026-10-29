import Foundation

public enum MenuItemID: String, CaseIterable, Codable, Sendable, Identifiable {
    case newText, newMarkdown, toggleHiddenFiles, openInTerminal, copyDirectoryPath
    public var id: String { rawValue }
    public var title: String {
        switch self {
        case .newText: "新建文本文件"
        case .newMarkdown: "新建 Markdown"
        case .toggleHiddenFiles: "切换隐藏文件显示"
        case .openInTerminal: "在终端中打开"
        case .copyDirectoryPath: "复制目录路径"
        }
    }
    public var symbol: String {
        switch self {
        case .newText: "doc.badge.plus"
        case .newMarkdown: "text.badge.plus"
        case .toggleHiddenFiles: "eye"
        case .openInTerminal: "terminal"
        case .copyDirectoryPath: "document.on.document"
        }
    }
}

public enum TerminalBundle: String, CaseIterable, Codable, Identifiable, Sendable {
    case terminal = "com.apple.Terminal"
    case iTerm2 = "com.googlecode.iterm2"
    public var id: String { rawValue }
    public var title: String { self == .terminal ? "Terminal" : "iTerm2" }
}

public enum ShellKind: String, Codable, CaseIterable, Identifiable, Sendable {
    case systemDefault = "default"
    case bash, zsh, fish
    public var id: String { rawValue }
    public var title: String {
        switch self {
        case .systemDefault: "终端默认 Shell"
        case .bash: "Bash"
        case .zsh: "Zsh"
        case .fish: "Fish"
        }
    }
}

public struct MenuItemPreference: Codable, Equatable, Sendable, Identifiable {
    public let id: MenuItemID
    public var isVisible: Bool
    public init(id: MenuItemID, isVisible: Bool) { self.id = id; self.isVisible = isVisible }
}

public struct GeneralPreferences: Codable, Equatable, Sendable {
    public var orderedMenuItems: [MenuItemPreference]
    public var preferredTerminal: TerminalBundle
    public var selectedShell: ShellKind
    public var clearAfterCD: Bool
    public var showMenuBarIcon: Bool
    public var showDockIcon: Bool
    public var useAccessibilityToggleForHiddenFiles: Bool
    public var monitoredFolderPaths: [String]

    public static let `default` = GeneralPreferences(
        orderedMenuItems: MenuItemID.allCases.map { MenuItemPreference(id: $0, isVisible: true) },
        preferredTerminal: .terminal,
        selectedShell: .systemDefault,
        clearAfterCD: true,
        showMenuBarIcon: true,
        showDockIcon: false,
        useAccessibilityToggleForHiddenFiles: false,
        monitoredFolderPaths: [NSHomeDirectory()]
    )

    // Older preference snapshots and malformed orders are normalized without losing visibility.
    public func normalized() -> GeneralPreferences {
        var copy = self
        var seen = Set<MenuItemID>()
        copy.orderedMenuItems = orderedMenuItems.filter { seen.insert($0.id).inserted }
        copy.orderedMenuItems += MenuItemID.allCases.filter { !seen.contains($0) }.map { .init(id: $0, isVisible: true) }
        copy.monitoredFolderPaths = MonitoredFolders.normalize(monitoredFolderPaths)
        return copy
    }

    private enum CodingKeys: String, CodingKey {
        case orderedMenuItems, preferredTerminal, selectedShell, clearAfterCD
        case showMenuBarIcon, showDockIcon, useAccessibilityToggleForHiddenFiles, monitoredFolderPaths
    }
    public init(orderedMenuItems: [MenuItemPreference], preferredTerminal: TerminalBundle,
                selectedShell: ShellKind, clearAfterCD: Bool, showMenuBarIcon: Bool,
                showDockIcon: Bool, useAccessibilityToggleForHiddenFiles: Bool,
                monitoredFolderPaths: [String]) {
        self.orderedMenuItems = orderedMenuItems
        self.preferredTerminal = preferredTerminal
        self.selectedShell = selectedShell
        self.clearAfterCD = clearAfterCD
        self.showMenuBarIcon = showMenuBarIcon
        self.showDockIcon = showDockIcon
        self.useAccessibilityToggleForHiddenFiles = useAccessibilityToggleForHiddenFiles
        self.monitoredFolderPaths = monitoredFolderPaths
    }
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        orderedMenuItems = try values.decodeIfPresent([MenuItemPreference].self, forKey: .orderedMenuItems) ?? Self.default.orderedMenuItems
        preferredTerminal = try values.decodeIfPresent(TerminalBundle.self, forKey: .preferredTerminal) ?? .terminal
        selectedShell = try values.decodeIfPresent(ShellKind.self, forKey: .selectedShell) ?? .systemDefault
        clearAfterCD = try values.decodeIfPresent(Bool.self, forKey: .clearAfterCD) ?? true
        showMenuBarIcon = try values.decodeIfPresent(Bool.self, forKey: .showMenuBarIcon) ?? true
        showDockIcon = try values.decodeIfPresent(Bool.self, forKey: .showDockIcon) ?? false
        useAccessibilityToggleForHiddenFiles = try values.decodeIfPresent(Bool.self, forKey: .useAccessibilityToggleForHiddenFiles) ?? false
        monitoredFolderPaths = try values.decodeIfPresent([String].self, forKey: .monitoredFolderPaths) ?? [NSHomeDirectory()]
    }
}

public final class SharedPreferences: @unchecked Sendable {
    public static let suiteName = "group.com.wuhunyu.literight"
    private let defaults: UserDefaults
    private let key = "generalPreferences"
    public init(userDefaults: UserDefaults? = nil) {
        // An unavailable App Group must not crash Finder; reads fall back to defaults.
        defaults = userDefaults ?? UserDefaults(suiteName: Self.suiteName) ?? .standard
    }
    public func load() -> GeneralPreferences {
        guard let data = defaults.data(forKey: key),
              let value = try? JSONDecoder().decode(GeneralPreferences.self, from: data) else { return .default }
        return value.normalized()
    }
    public func save(_ value: GeneralPreferences) throws {
        defaults.set(try JSONEncoder().encode(value.normalized()), forKey: key)
        // Persist before a cross-process Finder refresh notification is posted.
        _ = defaults.synchronize()
    }
}

public struct ResolvedTarget: Equatable, Sendable {
    public enum SourceKind: String, Sendable { case blankArea, files, folder, mixed, unsupported }
    public let directoryURL: URL?
    public let sourceKind: SourceKind
    public var allowsDirectoryActions: Bool { directoryURL != nil }
    public var allowsCopyPath: Bool { directoryURL != nil }
    public init(directoryURL: URL?, sourceKind: SourceKind) {
        self.directoryURL = directoryURL
        self.sourceKind = sourceKind
    }
}

public enum LiteRightError: LocalizedError, Sendable {
    case invalidDirectory, permissionDenied, diskFull, readOnlyVolume, tooManyNameConflicts
    case requestUnavailable, requestExpired, requestAlreadyProcessed, unsupportedAction
    case terminalUnavailable, shellUnavailable, operationFailed(String)
    case posix(Int32)

    public var errorDescription: String? {
        switch self {
        case .invalidDirectory: "目标目录不存在、已移动或不可访问。"
        case .permissionDenied: "没有权限访问目标目录。请检查 Finder 文件权限。"
        case .diskFull: "磁盘空间不足，无法创建文件。"
        case .readOnlyVolume: "目标卷为只读，不能创建文件。"
        case .tooManyNameConflicts: "同名文件数量过多，无法安全创建。"
        case .requestUnavailable: "操作请求不存在，请重新打开右键菜单。"
        case .requestExpired: "操作请求已过期，请重新操作。"
        case .requestAlreadyProcessed: "此请求已处理或正在处理，不会重复执行。"
        case .unsupportedAction: "请求的操作不受支持。"
        case .terminalUnavailable: "指定终端应用未安装，请在设置中选择可用的终端。"
        case .shellUnavailable: "所选 Shell 已不存在，请在终端设置中重新选择。"
        case let .operationFailed(detail): detail
        case let .posix(code): "系统错误（\(code)）：\(String(cString: strerror(code)))"
        }
    }
}
