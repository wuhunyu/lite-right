import Foundation
import AppKit
import XCTest
import Darwin

/// Exercises the DEBUG (unsigned) URL dispatch through LaunchServices on a
/// real hosted macOS GUI. This is not a replacement for Finder click testing.
final class PreviewOperationUITests: XCTestCase {
    @MainActor
    func testDeepLinkCreatesMarkdownWithinMonitoredLoginHome() throws {
        let userHome: String = {
            if let record = getpwuid(getuid()), let path = record.pointee.pw_dir {
                return String(cString: path)
            }
            return NSHomeDirectory()
        }()
        let directory = URL(fileURLWithPath: userHome, isDirectory: true)
            .appendingPathComponent("LiteRightPreviewUITest-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let app = XCUIApplication(bundleIdentifier: "com.wuhunyu.literight")
        app.launchArguments = ["--literight-probe-show-settings"]
        app.launch()
        defer { app.terminate() }
        XCTAssertTrue(app.windows.firstMatch.waitForExistence(timeout: 20))

        let request: [String: Any] = [
            "schemaVersion": 1,
            "id": UUID().uuidString,
            "action": "newMarkdown",
            "directoryPath": directory.path,
            "createdAt": Date().timeIntervalSinceReferenceDate
        ]
        let bytes = try JSONSerialization.data(withJSONObject: request)
        let encoded = bytes.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        let opener = Process()
        opener.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        opener.arguments = ["-b", "com.wuhunyu.literight", "lite-right://run?request=\(encoded)"]
        try opener.run()
        opener.waitUntilExit()
        XCTAssertEqual(opener.terminationStatus, 0, "LaunchServices must deliver the preview request")

        let destination = directory.appendingPathComponent("untitled.md")
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate { _, _ in FileManager.default.fileExists(atPath: destination.path) },
            object: nil
        )
        XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: 15), .completed,
                       "The running host must execute an actual request without an App Group")
    }
    /// Real clipboard verification through the unsigned preview's deep-link
    /// transport and host dispatcher. Finder selection itself is still P0.
    @MainActor
    func testDeepLinkCopiesSelectedFileFullAbsolutePathToPasteboard() throws {
        let home: String = {
            if let record = getpwuid(getuid()), let path = record.pointee.pw_dir {
                return String(cString: path)
            }
            return NSHomeDirectory()
        }()
        let directory = URL(fileURLWithPath: home, isDirectory: true)
            .appendingPathComponent("LiteRightCopyUITest-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let file = directory.appendingPathComponent("中文 test file.md")
        XCTAssertTrue(FileManager.default.createFile(atPath: file.path, contents: nil))
        let app = XCUIApplication(bundleIdentifier: "com.wuhunyu.literight")
        app.launchArguments = ["--literight-probe-show-settings"]
        app.launch()
        defer { app.terminate() }
        XCTAssertTrue(app.windows.firstMatch.waitForExistence(timeout: 20))

        NSPasteboard.general.clearContents()
        XCTAssertTrue(NSPasteboard.general.setString("before-lite-right-copy", forType: .string))

        let request: [String: Any] = [
            "schemaVersion": 1,
            "id": UUID().uuidString,
            "action": "copyDirectoryPath",
            "directoryPath": file.path,
            "createdAt": Date().timeIntervalSinceReferenceDate
        ]
        let payload = try JSONSerialization.data(withJSONObject: request)
        let text = payload.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        let opener = Process()
        opener.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        opener.arguments = ["-b", "com.wuhunyu.literight", "lite-right://run?request=\(text)"]
        try opener.run()
        opener.waitUntilExit()
        XCTAssertEqual(opener.terminationStatus, 0)

        let expected = file.standardizedFileURL.path
        let predicate = NSPredicate { _, _ in
            NSPasteboard.general.string(forType: .string) == expected
        }
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: 15), .completed,
                       "The host must copy the selected file's full path rather than its parent")
    }

}
