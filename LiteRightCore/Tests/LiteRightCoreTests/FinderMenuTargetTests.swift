import XCTest
@testable import LiteRightCore

final class FinderMenuTargetTests: XCTestCase {
    private var root: URL!
    override func setUpWithError() throws {
        root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    }
    override func tearDownWithError() throws {
        try FileManager.default.removeItem(at: root)
    }

    func testBlankAreaUsesTargetedContainer() {
        let result = FinderMenuTarget.resolve(context: .container, targetedURL: root, selectedItemURLs: nil)
        XCTAssertEqual(result.directoryURL, root.standardizedFileURL)
        XCTAssertEqual(result.sourceKind, .blankArea)
    }

    func testItemMenuUsesSelectedFileParent() throws {
        let file = root.appendingPathComponent("file.txt")
        XCTAssertTrue(FileManager.default.createFile(atPath: file.path, contents: nil))
        let result = FinderMenuTarget.resolve(context: .items, targetedURL: root, selectedItemURLs: [file])
        XCTAssertEqual(result.directoryURL, root.standardizedFileURL)
    }

    func testItemMenuFallsBackToClickedTargetWhenSelectionUnavailable() throws {
        let file = root.appendingPathComponent("file.txt")
        XCTAssertTrue(FileManager.default.createFile(atPath: file.path, contents: nil))
        let result = FinderMenuTarget.resolve(context: .items, targetedURL: file, selectedItemURLs: nil)
        XCTAssertEqual(result.directoryURL, root.standardizedFileURL)
    }

    func testSidebarMenuUsesClickedFolder() throws {
        let sub = root.appendingPathComponent("selected", isDirectory: true)
        try FileManager.default.createDirectory(at: sub, withIntermediateDirectories: true)
        let result = FinderMenuTarget.resolve(context: .sidebar, targetedURL: sub, selectedItemURLs: nil)
        XCTAssertEqual(result.directoryURL, sub.standardizedFileURL)
    }

    func testMixedDirectoriesDisablePathActions() throws {
        let sub = root.appendingPathComponent("another", isDirectory: true)
        try FileManager.default.createDirectory(at: sub, withIntermediateDirectories: true)
        let file = root.appendingPathComponent("file.txt")
        XCTAssertTrue(FileManager.default.createFile(atPath: file.path, contents: nil))
        let result = FinderMenuTarget.resolve(context: .items, targetedURL: file, selectedItemURLs: [file, sub])
        XCTAssertNil(result.directoryURL)
        XCTAssertFalse(result.allowsDirectoryActions)
    }

    func testToolbarDoesNotInventDirectory() {
        let result = FinderMenuTarget.resolve(context: .toolbar, targetedURL: root, selectedItemURLs: nil)
        XCTAssertNil(result.directoryURL)
        XCTAssertEqual(result.sourceKind, .unsupported)
    }

    func testUnsupportedSearchBackgroundDoesNotFallBackHome() {
        let result = FinderMenuTarget.resolve(context: .container, targetedURL: nil, selectedItemURLs: nil)
        XCTAssertNil(result.directoryURL)
    }

    func testSearchItemResolvesItsRealParent() throws {
        let sub = root.appendingPathComponent("real parent", isDirectory: true)
        try FileManager.default.createDirectory(at: sub, withIntermediateDirectories: true)
        let file = sub.appendingPathComponent("搜索 结果.txt")
        XCTAssertTrue(FileManager.default.createFile(atPath: file.path, contents: nil))
        let result = FinderMenuTarget.resolve(context: .items, targetedURL: nil, selectedItemURLs: [file])
        XCTAssertEqual(result.directoryURL, sub.standardizedFileURL)
    }
}
