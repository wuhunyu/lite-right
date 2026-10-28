import XCTest
@testable import LiteRightCore
final class ShellCatalogTests: XCTestCase {
    func testUnavailableShellsRemainVisibleButDisabled() {
        let entries = ShellCatalog.detect(available: { $0 == "/bin/bash" })
        XCTAssertEqual(entries.count, 4)
        XCTAssertTrue(entries.first(where: { $0.kind == .bash })!.isAvailable)
        XCTAssertFalse(entries.first(where: { $0.kind == .zsh })!.isAvailable)
        XCTAssertFalse(entries.first(where: { $0.kind == .fish })!.isAvailable)
    }
    func testPrefersAppleSiliconFish() {
        let entries = ShellCatalog.detect(available: { $0 == "/opt/homebrew/bin/fish" })
        XCTAssertEqual(ShellCatalog.path(for: .fish, in: entries), "/opt/homebrew/bin/fish")
        XCTAssertNil(ShellCatalog.path(for: .zsh, in: entries))
    }
}