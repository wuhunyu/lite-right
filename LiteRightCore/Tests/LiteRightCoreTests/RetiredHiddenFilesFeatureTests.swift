import Foundation
import XCTest
@testable import LiteRightCore

final class RetiredHiddenFilesFeatureTests: XCTestCase {
    func testPublicMenuOnlyOffersFourSupportedActions() {
        XCTAssertEqual(
            MenuItemID.allCases,
            [.newText, .newMarkdown, .openInTerminal, .copyDirectoryPath]
        )
        XCTAssertNil(MenuItemID(rawValue: "toggleHiddenFiles"))
        XCTAssertNil(FinderActionTag.resolve(tag: 103))
        XCTAssertNil(FinderActionTag.resolve(tag: 203))
        XCTAssertNil(FinderActionTag.resolve(tag: 303))
    }

    func testLegacySettingsDropRetiredMenuWithoutLosingUserPreferences() throws {
        var settings = GeneralPreferences.default
        settings.preferredTerminal = .iTerm2
        settings.selectedShell = .zsh
        settings.orderedMenuItems = [
            .init(id: .copyDirectoryPath, isVisible: true),
            .init(id: .newText, isVisible: false),
            .init(id: .openInTerminal, isVisible: true),
            .init(id: .newMarkdown, isVisible: true)
        ]

        let currentData = try JSONEncoder().encode(settings)
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: currentData) as? [String: Any])
        var menu = try XCTUnwrap(object["orderedMenuItems"] as? [[String: Any]])
        menu.insert(["id": "toggleHiddenFiles", "isVisible": true], at: 1)
        object["orderedMenuItems"] = menu
        object["useAccessibilityToggleForHiddenFiles"] = true
        let legacyData = try JSONSerialization.data(withJSONObject: object)

        let restored = try JSONDecoder().decode(GeneralPreferences.self, from: legacyData).normalized()
        XCTAssertEqual(restored.preferredTerminal, .iTerm2)
        XCTAssertEqual(restored.selectedShell, .zsh)
        XCTAssertEqual(restored.orderedMenuItems.map(\.id),
                       [.copyDirectoryPath, .newText, .openInTerminal, .newMarkdown])
        XCTAssertFalse(try XCTUnwrap(restored.orderedMenuItems.first { $0.id == .newText }).isVisible)
    }

    func testPreviewTransportRejectsRetiredAction() throws {
        let legacy = OperationRequest(action: .newText, directoryPath: "/Users/fixture", terminalBundleID: nil)
        let encoded = try PreviewRequestLink.encode(legacy)
        let query = try XCTUnwrap(URLComponents(url: encoded, resolvingAgainstBaseURL: false)?.queryItems?.first?.value)
        let base64 = query.replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let padded = base64 + String(repeating: "=", count: (4 - base64.count % 4) % 4)
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(base64Encoded: padded)!) as? [String: Any])
        json["action"] = "toggleHiddenFiles"
        let bytes = try JSONSerialization.data(withJSONObject: json)
        let newBase64 = bytes.base64EncodedString().replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: "=", with: "")
        let tampered = try XCTUnwrap(URL(string: "lite-right://run?request=\(newBase64)"))
        XCTAssertThrowsError(try PreviewRequestLink.decode(tampered))
    }
}
