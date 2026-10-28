import Foundation

public struct ShellAvailability: Equatable, Sendable, Identifiable {
    public var kind: ShellKind
    public var executablePath: String?
    public var id: String { kind.id }
    public var isAvailable: Bool { kind == .systemDefault || executablePath != nil }
}

public enum ShellCatalog {
    // Never rely on 'which' or interpolated shell strings; use known absolute executable paths.
    private static let paths: [ShellKind: [String]] = [
        .bash: ["/bin/bash", "/usr/bin/bash", "/opt/homebrew/bin/bash", "/usr/local/bin/bash"],
        .zsh: ["/bin/zsh", "/usr/bin/zsh", "/opt/homebrew/bin/zsh", "/usr/local/bin/zsh"],
        .fish: ["/opt/homebrew/bin/fish", "/usr/local/bin/fish", "/usr/bin/fish", "/bin/fish"]
    ]

    public static func detect(available: (String) -> Bool = { FileManager.default.isExecutableFile(atPath: $0) }) -> [ShellAvailability] {
        ShellKind.allCases.map { kind in
            .init(kind: kind, executablePath: paths[kind]?.first(where: available))
        }
    }
    public static func path(for selected: ShellKind, in choices: [ShellAvailability] = detect()) -> String? {
        choices.first(where: { $0.kind == selected && $0.isAvailable })?.executablePath
    }
    public static func canUse(_ selected: ShellKind, in choices: [ShellAvailability] = detect()) -> Bool {
        choices.contains(where: { $0.kind == selected && $0.isAvailable })
    }
}
