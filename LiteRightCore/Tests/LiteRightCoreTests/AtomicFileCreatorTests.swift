import XCTest
@testable import LiteRightCore

final class AtomicFileCreatorTests: XCTestCase {
    func testNamingAndNeverOverwrites() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let original = root.appendingPathComponent("untitled.txt")
        try Data("keep".utf8).write(to: original)
        let a = try AtomicFileCreator.createFile(in: root, template: .text)
        let b = try AtomicFileCreator.createFile(in: root, template: .text)
        let c = try AtomicFileCreator.createFile(in: root, template: .markdown)
        XCTAssertEqual(a.lastPathComponent, "untitled_copy.txt")
        XCTAssertEqual(b.lastPathComponent, "untitled_copy_2.txt")
        XCTAssertEqual(c.lastPathComponent, "untitled.md")
        XCTAssertEqual(try Data(contentsOf: original), Data("keep".utf8))
        XCTAssertEqual(try Data(contentsOf: c).count, 0)
    }
    func testHundredConcurrentCreatesAreUnique() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let urls = try await withThrowingTaskGroup(of: URL.self) { group in
            for _ in 0..<100 { group.addTask { try AtomicFileCreator.createFile(in: root, template: .text) } }
            var results: [URL] = []
            for try await url in group { results.append(url) }
            return results
        }
        XCTAssertEqual(Set(urls).count, 100)
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: root.path).count, 100)
    }
    func testInvalidDestinationFails() {
        XCTAssertThrowsError(try AtomicFileCreator.createFile(in: URL(string: "https://example.org")!, template: .text))
    }
}
