import XCTest

/// Best-effort GUI tests on hosted macOS. They do not imply Finder extension authorization.
final class SettingsSmokeUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // Regression probes are DEBUG-only. They isolate AppKit status-item visibility
    // and settings-window composition; they do not verify Finder authorization.
    @MainActor
    func testProbeMinimalWindowWithoutStatusBar() throws {
        let app = XCUIApplication(bundleIdentifier: "com.wuhunyu.literight")
        app.launchArguments = ["--literight-probe-minimal-window", "--literight-probe-no-menubar"]
        app.launch()
        defer { app.terminate() }
        XCTAssertTrue(app.staticTexts["LiteRight Startup Probe"].waitForExistence(timeout: 20),
                      "A bare Window scene must launch without the status item or settings content")
    }

    @MainActor
    func testProbeRealSettingsWithoutStatusBar() throws {
        let app = XCUIApplication(bundleIdentifier: "com.wuhunyu.literight")
        app.launchArguments = ["--literight-probe-no-menubar"]
        app.launch()
        defer { app.terminate() }
        XCTAssertTrue(app.staticTexts["右键菜单"].firstMatch.waitForExistence(timeout: 20),
                      "Real settings should launch without the status item")
    }

    @MainActor
    func testProbeMinimalWindowWithStatusBar() throws {
        let app = XCUIApplication(bundleIdentifier: "com.wuhunyu.literight")
        app.launchArguments = ["--literight-probe-minimal-window"]
        app.launch()
        defer { app.terminate() }
        XCTAssertTrue(app.staticTexts["LiteRight Startup Probe"].waitForExistence(timeout: 20),
                      "A bare settings window should launch alongside the AppKit status item")
    }

    @MainActor
    func testGeneralSettingsCanConfigureFinderMonitoredFolders() throws {
        let app = XCUIApplication(bundleIdentifier: "com.wuhunyu.literight")
        app.launch()
        defer { app.terminate() }
        let general = app.staticTexts["通用"].firstMatch
        XCTAssertTrue(general.waitForExistence(timeout: 20))
        general.click()
        XCTAssertTrue(app.buttons["添加监控目录"].firstMatch.waitForExistence(timeout: 10),
                      "The native General settings page must allow adding monitored Finder roots")
    }

    @MainActor
    func testSettingsWindowIsActuallyLaunched() throws {
        let app = XCUIApplication(bundleIdentifier: "com.wuhunyu.literight")
        app.launch()
        defer { app.terminate() }
        XCTAssertTrue(app.windows.firstMatch.waitForExistence(timeout: 20),
                      "LiteRight must display its native preferences window")
    }

    @MainActor
    func testMenuVisibilityPersistsAcrossAppRestart() throws {
        let app = XCUIApplication(bundleIdentifier: "com.wuhunyu.literight")
        app.launch()
        defer { app.terminate() }

        let toggleLabel = "显示 新建 Markdown"
        var toggle = app.switches[toggleLabel]
        XCTAssertTrue(toggle.waitForExistence(timeout: 20),
                      "The menu visibility toggle must be accessible")

        let before = toggle.value as? String ?? ""
        toggle.click()
        let updated = toggle.value as? String ?? ""
        XCTAssertNotEqual(updated, before, "Clicking the toggle must change its value")

        // This killed/relaunched process must load the saved preference from disk,
        // not merely retain an in-memory SwiftUI state or App Group cache.
        app.terminate()
        app.launch()

        toggle = app.switches[toggleLabel]
        XCTAssertTrue(toggle.waitForExistence(timeout: 20))
        XCTAssertEqual(toggle.value as? String, updated,
                       "LiteRight menu visibility must survive a real process restart")

        // Avoid leaving the runner's own preferences modified for later tests.
        if updated != before {
            toggle.click()
        }
    }

    @MainActor
    func testInitialMenuPageContainsAllFiveActions() throws {
        let app = XCUIApplication(bundleIdentifier: "com.wuhunyu.literight")
        app.launch()
        defer { app.terminate() }
        XCTAssertTrue(app.windows.firstMatch.waitForExistence(timeout: 20))
        // Do not mutate real user preferences; only inspect the app's first page.
        for name in ["新建文本文件", "新建 Markdown", "切换隐藏文件显示", "在终端中打开", "复制目录路径"] {
            XCTAssertTrue(app.staticTexts[name].waitForExistence(timeout: 5),
                          "Expected the Finder action in the Settings list: \(name)")
        }
    }
}
