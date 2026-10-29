import XCTest

/// Best-effort GUI tests on hosted macOS. They do not imply Finder extension authorization.
final class SettingsSmokeUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // Startup isolation probes are DEBUG-only. Each launch changes exactly one
    // scene or window-content variable relative to the existing failing tests.
    // These diagnose app startup, not Finder authorization or menu interaction.
    @MainActor
    func testProbeMinimalWindowWithoutMenuBar() throws {
        let app = XCUIApplication(bundleIdentifier: "com.wuhunyu.literight")
        app.launchArguments = ["--literight-probe-minimal-window", "--literight-probe-no-menubar"]
        app.launch()
        defer { app.terminate() }
        XCTAssertTrue(app.staticTexts["LiteRight Startup Probe"].waitForExistence(timeout: 20),
                      "A bare Window scene must launch without MenuBarExtra or settings content")
    }

    @MainActor
    func testProbeRealSettingsWithoutMenuBar() throws {
        let app = XCUIApplication(bundleIdentifier: "com.wuhunyu.literight")
        app.launchArguments = ["--literight-probe-no-menubar"]
        app.launch()
        defer { app.terminate() }
        XCTAssertTrue(app.staticTexts["右键菜单"].firstMatch.waitForExistence(timeout: 20),
                      "Real settings should launch without MenuBarExtra")
    }

    @MainActor
    func testProbeMinimalWindowWithMenuBar() throws {
        let app = XCUIApplication(bundleIdentifier: "com.wuhunyu.literight")
        app.launchArguments = ["--literight-probe-minimal-window"]
        app.launch()
        defer { app.terminate() }
        XCTAssertTrue(app.staticTexts["LiteRight Startup Probe"].waitForExistence(timeout: 20),
                      "A bare settings window should launch alongside MenuBarExtra")
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
