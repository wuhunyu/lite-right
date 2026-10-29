import Foundation

/// Durable host-only preferences. The main app's settings must not depend on
/// Finder Sync's App Group being authorized (ad-hoc preview builds may be denied).
public final class HostPreferencesStore {
    public let fileURL: URL
    private let legacy: () -> GeneralPreferences

    public init(
        fileURL: URL? = nil,
        legacy: @escaping () -> GeneralPreferences = { SharedPreferences().load() }
    ) {
        let base = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first ?? FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support", isDirectory: true)
        self.fileURL = fileURL ?? base.appendingPathComponent(
            "LiteRight/preferences.json", isDirectory: false
        )
        self.legacy = legacy
    }

    /// Migrate any previously available shared preferences only on first load.
    /// Corrupt local data is an error, not a reason to overwrite user settings
    /// with default values.
    public func load() throws -> GeneralPreferences {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return legacy().normalized()
        }
        let bytes = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode(GeneralPreferences.self, from: bytes).normalized()
    }

    public func save(_ value: GeneralPreferences) throws {
        let bytes = try JSONEncoder().encode(value.normalized())
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true,
            attributes: [.posixPermissions: 0o700]
        )
        try bytes.write(to: fileURL, options: .atomic)
        guard try Data(contentsOf: fileURL) == bytes else {
            throw LiteRightError.operationFailed("LiteRight 本机偏好设置写入后无法验证，请检查磁盘权限。")
        }
    }
}
