import Foundation

public enum ShellKind: String, Codable, CaseIterable, Identifiable, Sendable {
    case systemDefault = "default", bash, zsh, fish
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
public struct ShellAvailability: Equatable, Sendable, Identifiable {
    public var kind: ShellKind
    public var executablePath: String?
    public var id: String { kind.id }
    public var isAvailable: Bool { kind == .systemDefault || executablePath != nil }
}
public enum ShellCatalog {
    private static let paths: [ShellKind: [String]] = [
        .bash: ["/bin/bash", "/usr/bin/bash", "/opt/homebrew/bin/bash", "/usr/local/bin/bash"],
        .zsh: ["/bin/zsh", "/usr/bin/zsh", "/opt/homebrew/bin/zsh", "/usr/local/bin/zsh"],
        .fish: ["/opt/homebrew/bin/fish", "/usr/local/bin/fish", "/usr/bin/fish", "/bin/fish"]
    ]
    public static func detect(available: (String) -> Bool = { FileManager.default.isExecutableFile(atPath: $0) }) -> [ShellAvailability] {
        ShellKind.allCases.map { .init(kind: $0, executablePath: paths[$0]?.first(where: available)) }
    }
    public static func path(for selected: ShellKind, in choices: [ShellAvailability] = detect()) -> String? {
        choices.first(where: { $0.kind == selected && $0.isAvailable })?.executablePath
    }
    public static func canUse(_ selected: ShellKind, in choices: [ShellAvailability] = detect()) -> Bool {
        choices.contains(where: { $0.kind == selected && $0.isAvailable })
    }
}