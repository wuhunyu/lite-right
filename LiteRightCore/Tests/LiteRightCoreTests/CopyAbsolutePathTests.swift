import XCTest
@testable import LiteRightCore

final class CopyAbsolutePathTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("LiteRightCopy-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try FileManager.default.removeItem(at: directory)
    }

    func testBlankAreaCopiesCurrentDirectory() {
        let target = FinderMenuTarget.resolve(
            context: .container, targetedURL: directory, selectedItemURLs: nil
        )
        XCTAssertEqual(target.copyPathURL?.path, directory.standardizedFileURL.path)
    }

    func testSelectedDirectoryCopiesSelectedDirectory() throws {
        let child = directory.appendingPathComponent("项目资料", isDirectory: true)
        try FileManager.default.createDirectory(at: child, withIntermediateDirectories: true)
        let target = FinderMenuTarget.resolve(
            context: .items, targetedURL: child, selectedItemURLs: [child]
        )
        XCTAssertEqual(target.copyPathURL?.path, child.standardizedFileURL.path)
        XCTAssertEqual(target.directoryURL?.path, child.standardizedFileURL.path)
    }

    func testSelectedFileCopiesFullFilePathButDirectoryOperationsKeepParent() throws {
        let file = directory.appendingPathComponent("测试文档.md")
        XCTAssertTrue(FileManager.default.createFile(atPath: file.path, contents: nil))
        let target = FinderMenuTarget.resolve(
            context: .items, targetedURL: file, selectedItemURLs: [file]
        )
        XCTAssertEqual(target.directoryURL?.path, directory.standardizedFileURL.path)
        XCTAssertEqual(target.copyPathURL?.path, file.standardizedFileURL.path)

        let copyRequest = OperationRequest.forFinderMenu(
            action: .copyDirectoryPath, directoryURL: target.directoryURL,
            copyPathURL: target.copyPathURL, preferredTerminal: .terminal
        )
        XCTAssertEqual(copyRequest.directoryPath, file.standardizedFileURL.path)

        let createRequest = OperationRequest.forFinderMenu(
            action: .newMarkdown, directoryURL: target.directoryURL,
            copyPathURL: target.copyPathURL, preferredTerminal: .terminal
        )
        XCTAssertEqual(createRequest.directoryPath, directory.standardizedFileURL.path)
    }

    func testClickedFileFallbackRetainsFullPath() throws {
        let file = directory.appendingPathComponent("clicked.txt")
        XCTAssertTrue(FileManager.default.createFile(atPath: file.path, contents: nil))
        let target = FinderMenuTarget.resolve(
            context: .items, targetedURL: file, selectedItemURLs: nil
        )
        XCTAssertEqual(target.copyPathURL?.path, file.standardizedFileURL.path)
    }

    func testCopyTargetAllowsExistingFileButRejectsMissingFile() throws {
        let file = directory.appendingPathComponent("actual.txt")
        XCTAssertTrue(FileManager.default.createFile(atPath: file.path, contents: nil))
        XCTAssertEqual(TargetResolver.validatedCopyTarget(file)?.path, file.standardizedFileURL.path)
        XCTAssertNil(TargetResolver.validatedCopyTarget(directory.appendingPathComponent("missing.txt")))
    }

    func testPreviewTransportRoundTripsSelectedFilePath() throws {
        let file = directory.appendingPathComponent("真实文件.txt")
        XCTAssertTrue(FileManager.default.createFile(atPath: file.path, contents: nil))
        let request = OperationRequest(action: .copyDirectoryPath,
                                       directoryPath: file.path, terminalBundleID: nil)
        let url = try PreviewRequestLink.encode(request)
        let decoded = try PreviewRequestLink.decode(url)
        XCTAssertEqual(decoded.directoryPath, file.standardizedFileURL.path)
    }
}
