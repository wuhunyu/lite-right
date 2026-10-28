import XCTest
@testable import LiteRightCore

final class TargetResolverTests: XCTestCase {
    private var root: URL!
    override func setUpWithError() throws {
        root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    }
    override func tearDownWithError() throws { try FileManager.default.removeItem(at: root) }

    func testBlankAreaUsesContainer() throws {
        let result = TargetResolver.resolve(containerURL: root, selectedItemURLs: [])
        XCTAssertEqual(result.directoryURL, root.standardizedFileURL)
        XCTAssertTrue(result.allowsDirectoryActions)
    }
    func testSingleFileUsesParent() throws {
        let file = root.appendingPathComponent("read me.txt")
        XCTAssertTrue(FileManager.default.createFile(atPath: file.path, contents: nil))
        XCTAssertEqual(TargetResolver.resolve(containerURL: nil, selectedItemURLs: [file]).directoryURL, root.standardizedFileURL)
    }
    func testSingleDirectoryUsesItself() throws {
        let sub = root.appendingPathComponent("sub", isDirectory: true)
        try FileManager.default.createDirectory(at: sub, withIntermediateDirectories: true)
        XCTAssertEqual(TargetResolver.resolve(containerURL: nil, selectedItemURLs: [sub]).directoryURL, sub.standardizedFileURL)
    }
    func testMultipleFilesInSameDirectory() throws {
        let a = root.appendingPathComponent("a"); let b = root.appendingPathComponent("b")
        XCTAssertTrue(FileManager.default.createFile(atPath: a.path, contents: nil))
        XCTAssertTrue(FileManager.default.createFile(atPath: b.path, contents: nil))
        XCTAssertEqual(TargetResolver.resolve(containerURL: nil, selectedItemURLs: [a, b]).directoryURL, root.standardizedFileURL)
    }
    func testMixedDirectoriesDisableActions() throws {
        let sub = root.appendingPathComponent("sub", isDirectory: true)
        try FileManager.default.createDirectory(at: sub, withIntermediateDirectories: true)
        let a = root.appendingPathComponent("a"); XCTAssertTrue(FileManager.default.createFile(atPath: a.path, contents: nil))
        let result = TargetResolver.resolve(containerURL: nil, selectedItemURLs: [a, sub])
        XCTAssertNil(result.directoryURL); XCTAssertFalse(result.allowsCopyPath)
    }
    func testSymbolicLinkToDirectoryIsTreatedAsFile() throws {
        let sub = root.appendingPathComponent("sub", isDirectory: true)
        let link = root.appendingPathComponent("linked")
        try FileManager.default.createDirectory(at: sub, withIntermediateDirectories: true)
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: sub)
        XCTAssertEqual(TargetResolver.resolve(containerURL: nil, selectedItemURLs: [link]).directoryURL, root.standardizedFileURL)
    }
    func testAppBundleIsTreatedAsFile() throws {
        let app = root.appendingPathComponent("App.app", isDirectory: true)
        try FileManager.default.createDirectory(at: app, withIntermediateDirectories: true)
        XCTAssertEqual(TargetResolver.resolve(containerURL: nil, selectedItemURLs: [app]).directoryURL, root.standardizedFileURL)
    }
    func testUnsupportedURLNeverFallsBackHome() {
        let result = TargetResolver.resolve(containerURL: URL(string: "https://example.org")!, selectedItemURLs: [])
        XCTAssertNil(result.directoryURL); XCTAssertFalse(result.allowsDirectoryActions)
    }
    func testMissingSelectedFileDoesNotReturnParent() {
        let result = TargetResolver.resolve(containerURL: root, selectedItemURLs: [root.appendingPathComponent("gone")])
        XCTAssertNil(result.directoryURL)
    }
    func testMixedFileAndRemoteURLDisablesEverything() throws {
        let f = root.appendingPathComponent("a")
        XCTAssertTrue(FileManager.default.createFile(atPath: f.path, contents: nil))
        let result = TargetResolver.resolve(containerURL: root, selectedItemURLs: [f, URL(string: "https://example.org")!])
        XCTAssertNil(result.directoryURL)
    }
    func testMissingContainerDisablesActions() {
        let result = TargetResolver.resolve(containerURL: nil, selectedItemURLs: [])
        XCTAssertNil(result.directoryURL)
    }
    func testSelectedFileInOtherDirectoryUsesRealParent() throws {
        let other = root.appendingPathComponent("other", isDirectory: true)
        try FileManager.default.createDirectory(at: other, withIntermediateDirectories: true)
        let file = other.appendingPathComponent("a"); XCTAssertTrue(FileManager.default.createFile(atPath: file.path, contents: nil))
        XCTAssertEqual(TargetResolver.resolve(containerURL: root, selectedItemURLs: [file]).directoryURL, other.standardizedFileURL)
    }
}
