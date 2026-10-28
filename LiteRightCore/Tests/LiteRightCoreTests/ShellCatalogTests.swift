import XCTest
@testable import LiteRightCore

final class ShellCatalogTests: XCTestCase {
    func testDetectsOnlyAvailableShellsAndMarksUnavailable() {
        let entries = ShellCatalog.detect(available: { $0 == "/bin/bash" })
        XCTAssertTrue(entries.first(where: { $0.kind == .systemDefault })!.isAvailable)
        XCTAssertEqual(entries.first(where: { $0.kind == .bash })!.executablePath, "/bin/bash")
        XCTAssertFalse(entries.first(where: { $0.kind == .zsh })!.isAvailable)
        XCTAssertFalse(entries.first(where: { $0.kind == .fish })!.isAvailable)
    }
    func testPrefersAppleSiliconFishAndDisallowsMissingSelectedShell() {
        let entries = ShellCatalog.detect(available: { $0 == "/opt/homebrew/bin/fish" || $0 == "/usr/local/bin/fish" })
        XCTAssertEqual(ShellCatalog.path(for: .fish, in: entries), "/opt/homebrew/bin/fish")
        XCTAssertNil(ShellCatalog.path(for: .zsh, in: entries))
    }
    func testDefaultShellRequiresNoExecutableOverride() {
        XCTAssertNil(ShellCatalog.path(for: .systemDefault, in: ShellCatalog.detect(available: { _ in false })))
    }
}
