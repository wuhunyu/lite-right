import Foundation

/// Preview-only, untrusted settings announcements. Never use this transport for actions.
public enum PreviewMenuSync {
    public static let requestName = Notification.Name("com.wuhunyu.literight.preview.settings-request")
    public static let snapshotName = Notification.Name("com.wuhunyu.literight.preview.settings-snapshot")
    public static let maximumBytes = 32_768

    public static func encode(_ value: GeneralPreferences) -> String? {
        guard let data = try? JSONEncoder().encode(value.normalized()),
              data.count <= maximumBytes else { return nil }
        return data.base64EncodedString()
    }

    public static func decode(_ encoded: String?) -> GeneralPreferences? {
        guard let encoded, encoded.count <= maximumBytes * 2,
              let data = Data(base64Encoded: encoded), data.count <= maximumBytes,
              let value = try? JSONDecoder().decode(GeneralPreferences.self, from: data)
        else { return nil }
        let result = value.normalized()
        guard result.monitoredFolderPaths.count <= 64,
              result.orderedMenuItems.count == MenuItemID.allCases.count else { return nil }
        return result
    }
}
