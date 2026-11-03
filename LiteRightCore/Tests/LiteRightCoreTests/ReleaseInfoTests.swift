import XCTest
import Foundation
@testable import LiteRightCore

final class ReleaseInfoTests: XCTestCase {
    func testPreviewChannelAddsOnlyAUserFacingSuffix() {
        XCTAssertEqual(ReleaseInfo.displayVersion(marketingVersion: "1.0.0", channel: "preview"), "1.0.0-preview")
        XCTAssertEqual(ReleaseInfo.displayVersion(marketingVersion: "1.0.0", channel: "release"), "1.0.0")
        XCTAssertEqual(ReleaseInfo.displayVersion(marketingVersion: "1.0.0", channel: ""), "1.0.0")
    }

    func testDiagnosticSummaryReportsRealStatesWithoutPrivatePaths() {
        let summary = ReleaseInfo.diagnosticSummary(
            displayedVersion: "1.0.0-preview", build: "12",
            operatingSystem: "macOS 27.0.1 (Build 26A434)", architecture: "arm64",
            finderExtensionEnabled: true, transport: "Preview IPC", monitoredFolderCount: 2
        )
        XCTAssertTrue(summary.contains("LiteRight 1.0.0-preview (Build 12)"))
        XCTAssertTrue(summary.contains("架构：arm64"))
        XCTAssertTrue(summary.contains("Finder 扩展：系统报告已启用"))
        XCTAssertTrue(summary.contains("通信方式：Preview IPC"))
        XCTAssertTrue(summary.contains("监控目录数量：2"))
        XCTAssertFalse(summary.contains("/Users/"))
        XCTAssertFalse(summary.contains("CPUs"))
    }

    func testDisabledFinderIsNotReportedAsSuccess() {
        let summary = ReleaseInfo.diagnosticSummary(
            displayedVersion: "1.0.0-preview", build: "1",
            operatingSystem: "macOS 27", architecture: "arm64",
            finderExtensionEnabled: false, transport: "Preview IPC", monitoredFolderCount: 0
        )
        XCTAssertTrue(summary.contains("Finder 扩展：未启用或无法确认"))
    }
}
