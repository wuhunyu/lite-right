import XCTest
import AppKit

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
        app.launchArguments = ["--literight-probe-minimal-window", "--literight-probe-no-menubar", "--literight-probe-show-settings"]
        app.launch()
        defer { app.terminate() }
        XCTAssertTrue(app.staticTexts["LiteRight Startup Probe"].waitForExistence(timeout: 20),
                      "A bare Window scene must launch without the status item or settings content")
    }

    @MainActor
    func testProbeRealSettingsWithoutStatusBar() throws {
        let app = XCUIApplication(bundleIdentifier: "com.wuhunyu.literight")
        app.launchArguments = ["--literight-probe-no-menubar", "--literight-probe-show-settings"]
        app.launch()
        defer { app.terminate() }
        XCTAssertTrue(app.staticTexts["右键菜单"].firstMatch.waitForExistence(timeout: 20),
                      "Real settings should launch without the status item")
    }

    @MainActor
    func testProbeMinimalWindowWithStatusBar() throws {
        let app = XCUIApplication(bundleIdentifier: "com.wuhunyu.literight")
        app.launchArguments = ["--literight-probe-minimal-window", "--literight-probe-show-settings"]
        app.launch()
        defer { app.terminate() }
        XCTAssertTrue(app.staticTexts["LiteRight Startup Probe"].waitForExistence(timeout: 20),
                      "A bare settings window should launch alongside the AppKit status item")
    }

    @MainActor
    func testGeneralSettingsCanConfigureFinderMonitoredFolders() throws {
        let app = XCUIApplication(bundleIdentifier: "com.wuhunyu.literight")
        app.launchArguments = ["--literight-probe-show-settings"]
        app.launch()
        defer { app.terminate() }
        let general = app.staticTexts["通用"].firstMatch
        XCTAssertTrue(general.waitForExistence(timeout: 20))
        general.click()
        XCTAssertTrue(app.buttons["管理 Finder 扩展"].firstMatch.waitForExistence(timeout: 10))
        XCTAssertFalse(app.staticTexts["权限管理"].exists)
        XCTAssertTrue(app.buttons["添加监控目录"].firstMatch.waitForExistence(timeout: 10),
                      "The native General settings page must allow adding monitored Finder roots")
    }

    @MainActor
    func testSettingsWindowIsActuallyLaunched() throws {
        let app = XCUIApplication(bundleIdentifier: "com.wuhunyu.literight")
        app.launchArguments = ["--literight-probe-show-settings"]
        app.launch()
        defer { app.terminate() }
        XCTAssertTrue(app.windows.firstMatch.waitForExistence(timeout: 20),
                      "LiteRight must display its native preferences window")
    }

    /// AppKit-hosted SwiftUI must not place the main detail heading under
    /// a translucent titlebar/toolbar. Capture a screenshot in CI to diagnose.
    @MainActor
    func testSettingsTitleAndDetailHeaderAreVisible() throws {
        let app = XCUIApplication(bundleIdentifier: "com.wuhunyu.literight")
        app.launchArguments = ["--literight-probe-show-settings"]
        app.launch()
        defer { app.terminate() }

        let window = app.windows.firstMatch
        XCTAssertTrue(window.waitForExistence(timeout: 20))
        // Hosted macOS accessibility sometimes exposes NSWindow.label as
        // empty even when the window title is visible. Verify if available,
        // then keep a screenshot for a human titlebar/side-material review.
        if !window.label.isEmpty {
            XCTAssertEqual(window.label, "LiteRight", "Only the brand should appear in the titlebar")
        }
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "LiteRight-settings-titlebar-and-sidebar"
        attachment.lifetime = .keepAlways
        add(attachment)

        let title = app.staticTexts["menu-settings-title"].firstMatch
        let description = app.staticTexts["menu-settings-description"].firstMatch
        XCTAssertTrue(title.waitForExistence(timeout: 10),
                      "The menu page must provide an accessible detail heading")
        XCTAssertTrue(description.waitForExistence(timeout: 10))
        XCTAssertTrue(title.isHittable, "The detail heading must not be covered by the titlebar")
        XCTAssertTrue(description.isHittable, "The description must not be covered by a toolbar")
        XCTAssertGreaterThan(title.frame.minY, window.frame.minY + 30,
                             "Detail headings should begin below the traffic-light/titlebar region")
        XCTAssertLessThan(title.frame.maxY, description.frame.minY,
                          "The detail heading must be laid out above its description")

    }

    /// Double-clicking a stopped LiteRight.app must show Settings; the
    /// custom URL tests below separately verify silent Finder work.
    @MainActor
    func testManualLaunchOpensSettingsWithoutDebugFlags() throws {
        let app = XCUIApplication(bundleIdentifier: "com.wuhunyu.literight")
        app.launch()
        defer { app.terminate() }
        XCTAssertTrue(app.windows.firstMatch.waitForExistence(timeout: 15),
                      "A normal user launch of LiteRight must open Settings")
    }

    /// Finder re-opening an existing accessory app is a user-initiated action.
    /// It must not be confused with a lite-right://run operation.
    @MainActor
    func testExplicitAppReopenOpensSettingsWhenRunningHeadless() throws {
        let app = XCUIApplication(bundleIdentifier: "com.wuhunyu.literight")
        app.launchArguments = ["--literight-probe-start-headless", "--literight-probe-no-menubar"]
        app.launch()
        defer { app.terminate() }
        XCTAssertFalse(app.windows.firstMatch.exists)

        let reopen = Process()
        reopen.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        reopen.arguments = ["-b", "com.wuhunyu.literight"]
        try reopen.run()
        reopen.waitUntilExit()
        XCTAssertEqual(reopen.terminationStatus, 0)
        XCTAssertTrue(app.windows.firstMatch.waitForExistence(timeout: 15),
                      "Explicitly opening the already running app must reveal Settings")
    }

    /// Read the actual on-disk snapshot rather than assuming macOS 27
    /// accessibility checkboxes expose a nonempty XCUIElement.value string.
    private func savedMarkdownVisibility(at file: URL) -> Bool? {
        guard let bytes = try? Data(contentsOf: file),
              let json = try? JSONSerialization.jsonObject(with: bytes) as? [String: Any],
              let entries = json["orderedMenuItems"] as? [[String: Any]],
              let entry = entries.first(where: { ($0["id"] as? String) == "newMarkdown" }) else {
            return nil
        }
        return entry["isVisible"] as? Bool
    }

    private func checkBoxValue(_ element: XCUIElement) -> Int? {
        if let number = element.value as? NSNumber { return number.intValue }
        if let string = element.value as? String { return Int(string) }
        return nil
    }

    @MainActor
    func testMenuVisibilityPersistsAcrossAppRestart() throws {
        let app = XCUIApplication(bundleIdentifier: "com.wuhunyu.literight")
        let testPreferences = FileManager.default.temporaryDirectory
            .appendingPathComponent("literight-ui-\(UUID().uuidString)", isDirectory: true)
            .appendingPathComponent("preferences.json")
        defer { try? FileManager.default.removeItem(at: testPreferences.deletingLastPathComponent()) }
        app.launchArguments = [
            "--literight-probe-show-settings",
            "--literight-probe-preferences-path=\(testPreferences.path)"
        ]
        app.launch()
        defer { app.terminate() }
        let toggleIdentifier = "menu-visibility-newMarkdown"
        let baseline = savedMarkdownVisibility(at: testPreferences) ?? true

        app.activate()
        let settingsTitle = app.staticTexts["menu-settings-title"]
        XCTAssertTrue(settingsTitle.waitForExistence(timeout: 10))
        let debugValue = settingsTitle.value as? String ?? ""
        print("LiteRight UI probe: \(debugValue)")
        XCTAssertTrue(debugValue.hasPrefix("path=\(testPreferences.path)\n"),
                      "The app must use the isolated preferences file supplied by its probe argument")
        var toggle = app.checkBoxes.matching(identifier: toggleIdentifier).firstMatch
        if !toggle.waitForExistence(timeout: 2) {
            toggle = app.switches.matching(identifier: toggleIdentifier).firstMatch
        }
        XCTAssertTrue(toggle.waitForExistence(timeout: 20),
                      "The menu visibility toggle must be exposed as a checkbox or switch")
        XCTAssertTrue(toggle.isHittable,
                      "The settings window must keep menu controls inside the visible screen; window=\(app.windows.firstMatch.frame), control=\(toggle.frame)")
        if toggle.isHittable {
            toggle.click()
        } else {
            toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).click()
        }
        // Hosted macOS XCUITest reports the checkbox click but does not always
        // dispatch it as a state change. Space activates the focused checkbox
        // through the same native accessibility control.
        if checkBoxValue(toggle) == 1 {
            app.typeKey(.space, modifierFlags: [])
        }
        let toggleGeometry = "type=\(toggle.elementType.rawValue), value=\(String(describing: toggle.value)), selected=\(toggle.isSelected), hittable=\(toggle.isHittable), enabled=\(toggle.isEnabled), frame=\(toggle.frame)"
        let alert = app.alerts.firstMatch
        let saveDeadline = Date().addingTimeInterval(3)
        while Date() < saveDeadline, savedMarkdownVisibility(at: testPreferences) != !baseline {
            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        }
        XCTAssertEqual(savedMarkdownVisibility(at: testPreferences), !baseline,
                       "The native toggle must save its changed value; \(toggleGeometry); alert=\(alert.exists ? alert.label : "none"); accessibility=\(app.debugDescription)")

        // Terminate and relaunch: the second click must restore the persisted
        // value, proving the new process loaded it instead of a default.
        app.terminate()
        app.launch()
        app.activate()
        toggle = app.checkBoxes.matching(identifier: toggleIdentifier).firstMatch
        if !toggle.waitForExistence(timeout: 2) {
            toggle = app.switches.matching(identifier: toggleIdentifier).firstMatch
        }
        XCTAssertTrue(toggle.waitForExistence(timeout: 20))
        if toggle.isHittable {
            toggle.click()
        } else {
            toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).click()
        }
        if checkBoxValue(toggle) == 0 {
            app.typeKey(.space, modifierFlags: [])
        }
        XCTAssertEqual(savedMarkdownVisibility(at: testPreferences), baseline,
                       "The relaunched app must use the saved preference")
    }

    @MainActor
    func testInitialMenuPageContainsAllFourActions() throws {
        let app = XCUIApplication(bundleIdentifier: "com.wuhunyu.literight")
        app.launchArguments = ["--literight-probe-show-settings"]
        app.launch()
        defer { app.terminate() }
        XCTAssertTrue(app.windows.firstMatch.waitForExistence(timeout: 20))
        // Do not mutate real user preferences; only inspect the app's first page.
        for name in ["新建文本文件", "新建 Markdown", "在终端中打开", "复制绝对路径"] {
            XCTAssertTrue(app.staticTexts[name].waitForExistence(timeout: 5),
                          "Expected the Finder action in the Settings list: \(name)")
        }
    }
    /// Use the same versioned preview transport as Finder Sync; no mock route.
    private func previewCopyURL(directory: String) throws -> URL {
        let request: [String: Any] = [
            "schemaVersion": 1,
            "id": UUID().uuidString,
            "action": "copyDirectoryPath",
            "directoryPath": directory,
            "createdAt": Date().timeIntervalSinceReferenceDate
        ]
        let json = try JSONSerialization.data(withJSONObject: request)
        let encoded = json.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        var url = URLComponents()
        url.scheme = "lite-right"
        url.host = "run"
        url.queryItems = [URLQueryItem(name: "request", value: encoded)]
        return try XCTUnwrap(url.url)
    }

    private func requireClipboard(_ expected: String) {
        let limit = Date().addingTimeInterval(15)
        while Date() < limit {
            if NSPasteboard.general.string(forType: .string) == expected { break }
            RunLoop.current.run(until: Date().addingTimeInterval(0.15))
        }
        XCTAssertEqual(NSPasteboard.general.string(forType: .string), expected)
    }

    @MainActor
    func testFinderCopyURLRunsSilentlyInExistingProcess() throws {
        let app = XCUIApplication(bundleIdentifier: "com.wuhunyu.literight")
        app.launchArguments = ["--literight-probe-start-headless", "--literight-probe-no-menubar"]
        app.launch()
        defer { app.terminate() }
        XCTAssertFalse(app.windows.firstMatch.exists,
                       "A background Finder helper must not show Settings at launch")

        let home = FileManager.default.homeDirectoryForCurrentUser.path
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString("pre-action-marker", forType: .string)
        XCTAssertTrue(NSWorkspace.shared.open(try previewCopyURL(directory: home)))
        requireClipboard(home)
        XCTAssertFalse(app.windows.firstMatch.exists,
                       "A Finder action must not instantiate the Settings window")
    }

    @MainActor
    func testFinderCopyURLRunsSilentlyOnColdStart() throws {
        let app = XCUIApplication(bundleIdentifier: "com.wuhunyu.literight")
        app.launchArguments = ["--literight-probe-start-headless", "--literight-probe-no-menubar"]
        app.launch() // Register installed test app and URL handler.
        app.terminate()

        let home = FileManager.default.homeDirectoryForCurrentUser.path
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString("pre-action-marker", forType: .string)
        XCTAssertTrue(NSWorkspace.shared.open(try previewCopyURL(directory: home)))
        defer { app.terminate() }
        requireClipboard(home)
        XCTAssertFalse(app.windows.firstMatch.exists,
                       "Cold URL activation must not reveal a settings window")
    }

}
