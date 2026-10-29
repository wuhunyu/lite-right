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

    /// Read the actual on-disk snapshot rather than assuming macOS 27
    /// accessibility checkboxes expose a nonempty XCUIElement.value string.
    private func savedMarkdownVisibility() -> Bool? {
        let support = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first ?? FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support", isDirectory: true)
        let file = support.appendingPathComponent("LiteRight/preferences.json")
        guard let bytes = try? Data(contentsOf: file),
              let json = try? JSONSerialization.jsonObject(with: bytes) as? [String: Any],
              let entries = json["orderedMenuItems"] as? [[String: Any]],
              let entry = entries.first(where: { ($0["id"] as? String) == "newMarkdown" }) else {
            return nil
        }
        return entry["isVisible"] as? Bool
    }

    @MainActor
    func testMenuVisibilityPersistsAcrossAppRestart() throws {
        let app = XCUIApplication(bundleIdentifier: "com.wuhunyu.literight")
        app.launch()
        defer { app.terminate() }
        let toggleIdentifier = "menu-visibility-newMarkdown"
        let baseline = savedMarkdownVisibility() ?? true

        var toggle = app.descendants(matching: .any)
            .matching(identifier: toggleIdentifier).firstMatch
        XCTAssertTrue(toggle.waitForExistence(timeout: 20),
                      "The menu visibility toggle must be accessible")
        toggle.click()
        XCTAssertEqual(savedMarkdownVisibility(), !baseline,
                       "The first click must atomically save the new visibility to disk")

        // Terminate and relaunch: the second click must restore the persisted
        // value, proving the new process loaded it instead of a default.
        app.terminate()
        app.launch()
        toggle = app.descendants(matching: .any)
            .matching(identifier: toggleIdentifier).firstMatch
        XCTAssertTrue(toggle.waitForExistence(timeout: 20))
        toggle.click()
        XCTAssertEqual(savedMarkdownVisibility(), baseline,
                       "The relaunched app must use the saved preference")
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
