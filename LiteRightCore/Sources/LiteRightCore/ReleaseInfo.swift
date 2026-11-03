import Foundation

public enum ReleaseInfo {
    public static func displayVersion(marketingVersion: String, channel: String) -> String {
        let version = marketingVersion.isEmpty ? "未知版本" : marketingVersion
        return channel == "preview" ? "\(version)-preview" : version
    }

    public static func diagnosticSummary(
        displayedVersion: String, build: String, operatingSystem: String,
        architecture: String, finderExtensionEnabled: Bool,
        transport: String, monitoredFolderCount: Int
    ) -> String {
        [
            "LiteRight \(displayedVersion) (Build \(build))",
            operatingSystem,
            "架构：\(architecture)",
            "Finder 扩展：\(finderExtensionEnabled ? "系统报告已启用" : "未启用或无法确认")",
            "通信方式：\(transport)",
            "监控目录数量：\(monitoredFolderCount)"
        ].joined(separator: "\n")
    }
}
