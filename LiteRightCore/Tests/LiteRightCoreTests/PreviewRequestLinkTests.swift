import Foundation
import XCTest
@testable import LiteRightCore

final class PreviewRequestLinkTests: XCTestCase {
    func testRoundTripsAllFiveActionsWithUnicodeAndShellMetacharactersInDirectory() throws {
        for action in MenuItemID.allCases {
            let target = action == .toggleHiddenFiles ? nil :
                "/Users/fixture/项目 & 测试's \"quoted\" $(date)"
            let original = OperationRequest(
                action: action,
                directoryPath: target,
                terminalBundleID: action == .openInTerminal ? .terminal : nil
            )
            let url = try PreviewRequestLink.encode(original)
            XCTAssertEqual(url.scheme, "lite-right")
            XCTAssertEqual(url.host, "run")
            let decoded = try PreviewRequestLink.decode(url)
            XCTAssertEqual(decoded.id, original.id)
            XCTAssertEqual(decoded.action, original.action)
            XCTAssertEqual(decoded.directoryPath, original.directoryPath)
            XCTAssertEqual(decoded.terminalBundleID, original.terminalBundleID)
        }
    }

    func testRejectsMalformedOrExtraURLParameters() throws {
        let example = OperationRequest(action: .newMarkdown, directoryPath: "/Users/fixture",
                                       terminalBundleID: nil)
        let valid = try PreviewRequestLink.encode(example)
        for raw in [
            "https://run?request=AAA",
            "lite-right://evil?request=AAA",
            "lite-right://run?id=\(example.id.uuidString)",
            "lite-right://run?request=bad!",
            "lite-right://run?request=aaa&request=bbb",
            valid.absoluteString + "&extra=1",
            valid.absoluteString + "#fragment"
        ] {
            guard let url = URL(string: raw) else { XCTFail("invalid test URL"); continue }
            XCTAssertThrowsError(try PreviewRequestLink.decode(url), "Accepted \(raw)")
        }
    }

    func testRejectsOldFutureOrUnsupportedRequests() throws {
        for date in [Date(timeIntervalSinceNow: -120), Date(timeIntervalSinceNow: 120)] {
            let request = OperationRequest(action: .copyDirectoryPath, directoryPath: "/Users/fixture",
                                           terminalBundleID: nil, createdAt: date)
            XCTAssertThrowsError(try PreviewRequestLink.encode(request))
        }
        for path in ["/", "relative", "/Users/fixture/../sibling", "/Users/fixture/./tmp",
                     String(repeating: "a", count: 3000)] {
            let request = OperationRequest(action: .newText, directoryPath: path,
                                           terminalBundleID: nil)
            XCTAssertThrowsError(try PreviewRequestLink.encode(request), "Accepted \(path.prefix(40))")
        }
        let invalidToggle = OperationRequest(action: .toggleHiddenFiles, directoryPath: "/tmp",
                                             terminalBundleID: nil)
        XCTAssertThrowsError(try PreviewRequestLink.encode(invalidToggle))
    }

    func testRejectsOversizedDeepLink() {
        let huge = "lite-right://run?request=" + String(repeating: "A", count: 9000)
        XCTAssertThrowsError(try PreviewRequestLink.decode(URL(string: huge)!))
    }
}
