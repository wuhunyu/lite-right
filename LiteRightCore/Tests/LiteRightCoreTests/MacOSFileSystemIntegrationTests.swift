import Foundation
import XCTest
@testable import LiteRightCore

/// Exercises real filesystem calls rather than mocks. The suite runs on the macOS GitHub runner.
final class MacOSFileSystemIntegrationTests: XCTestCase {
    private func withDirectory<T>(_ name: String, _ body: (URL) throws -> T) throws -> T {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("LiteRight-Integration-\(UUID().uuidString)", isDirectory: true)
            .appendingPathComponent(name, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root.deletingLastPathComponent()) }
        return try body(root)
    }

    func testRealFileCreationInChineseAndQuotedPath() throws {
        try withDirectory("中文 空格 '单引号' $dollar", { directory in
            let text = try AtomicFileCreator.createFile(in: directory, template: .text)
            let markdown = try AtomicFileCreator.createFile(in: directory, template: .markdown)
            XCTAssertEqual(text.deletingLastPathComponent(), directory.standardizedFileURL)
            XCTAssertEqual(markdown.deletingLastPathComponent(), directory.standardizedFileURL)
            XCTAssertEqual(try Data(contentsOf: text), Data())
            XCTAssertEqual(try Data(contentsOf: markdown), Data())
            XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: directory.path).count, 2)
        })
    }

    func testRealFileCreationDoesNotOverwriteAnyExistingContents() throws {
        try withDirectory("collisions", { directory in
            for name in ["untitled.txt", "untitled_copy.txt", "untitled_copy_2.txt"] {
                try Data(name.utf8).write(to: directory.appendingPathComponent(name))
            }
            let created = try AtomicFileCreator.createFile(in: directory, template: .text)
            XCTAssertEqual(created.lastPathComponent, "untitled_copy_3.txt")
            for name in ["untitled.txt", "untitled_copy.txt", "untitled_copy_2.txt"] {
                XCTAssertEqual(try Data(contentsOf: directory.appendingPathComponent(name)), Data(name.utf8))
            }
        })
    }

    func testSymbolicLinkSelectionNeverWritesIntoLinkedFolder() throws {
        try withDirectory("linked-dirs", { root in
            let target = root.appendingPathComponent("real", isDirectory: true)
            try FileManager.default.createDirectory(at: target, withIntermediateDirectories: true)
            let link = root.appendingPathComponent("shortcut")
            try FileManager.default.createSymbolicLink(at: link, withDestinationURL: target)
            let selected = TargetResolver.resolve(containerURL: root, selectedItemURLs: [link])
            XCTAssertEqual(selected.directoryURL, root.standardizedFileURL)
            let created = try AtomicFileCreator.createFile(in: try XCTUnwrap(selected.directoryURL), template: .markdown)
            XCTAssertEqual(created.deletingLastPathComponent(), root.standardizedFileURL)
            XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: target.path).count, 0)
        })
    }

    func testDetectedShellsAreExecutableOnThisMachine() {
        let entries = ShellCatalog.detect()
        XCTAssertEqual(entries.map(\.kind), ShellKind.allCases)
        XCTAssertTrue(entries.first(where: { $0.kind == .systemDefault })?.isAvailable == true)
        for choice in entries where choice.kind != .systemDefault && choice.isAvailable {
            XCTAssertTrue(FileManager.default.isExecutableFile(atPath: choice.executablePath ?? ""),
                          "Detected a non-executable path for \(choice.kind)")
        }
        // No hardcoded assumption that optional shells are installed on a given runner.
    }
}
