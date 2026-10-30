import Foundation

/// An explicitly limited local transport for unsigned developer previews.
/// Custom URL schemes are untrusted input: callers can forge them. The host
/// MUST validate the target against its own monitored-root preferences before
/// executing any request. Production signed builds use RequestStore instead.
public enum PreviewRequestLink {
    private static let maxURLBytes = 6_000
    private static let maxPayloadBytes = 4_096
    private static let maxDirectoryBytes = 2_048
    private static let expiry: TimeInterval = 60
    private static let futureTolerance: TimeInterval = 5

    public static func encode(_ request: OperationRequest, now: Date = Date()) throws -> URL {
        try validate(request, now: now)
        let payload = try JSONEncoder().encode(request)
        guard payload.count <= maxPayloadBytes else { throw LiteRightError.unsupportedAction }
        let text = payload.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        var components = URLComponents()
        components.scheme = "lite-right"
        components.host = "run"
        components.queryItems = [URLQueryItem(name: "request", value: text)]
        guard let url = components.url, url.absoluteString.utf8.count <= maxURLBytes else {
            throw LiteRightError.requestUnavailable
        }
        return url
    }

    public static func decode(_ url: URL, now: Date = Date()) throws -> OperationRequest {
        guard url.absoluteString.utf8.count <= maxURLBytes,
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              components.scheme == "lite-right", components.host == "run",
              components.path.isEmpty, components.user == nil,
              components.password == nil, components.port == nil,
              components.fragment == nil,
              let parameters = components.queryItems, parameters.count == 1,
              parameters[0].name == "request", let encoded = parameters[0].value,
              !encoded.isEmpty, encoded.utf8.count <= maxURLBytes else {
            throw LiteRightError.unsupportedAction
        }
        guard encoded.utf8.allSatisfy({
            ($0 >= 65 && $0 <= 90) || ($0 >= 97 && $0 <= 122) ||
            ($0 >= 48 && $0 <= 57) || $0 == 45 || $0 == 95
        }) else {
            throw LiteRightError.unsupportedAction
        }
        let remainder = encoded.count % 4
        guard remainder != 1 else { throw LiteRightError.unsupportedAction }
        let base64 = encoded.replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
            + String(repeating: "=", count: (4 - remainder) % 4)
        guard let data = Data(base64Encoded: base64), data.count <= maxPayloadBytes,
              let request = try? JSONDecoder().decode(OperationRequest.self, from: data) else {
            throw LiteRightError.unsupportedAction
        }
        try validate(request, now: now)
        return request
    }

    private static func validate(_ request: OperationRequest, now: Date) throws {
        guard request.schemaVersion == 1 else { throw LiteRightError.unsupportedAction }
        guard now.timeIntervalSince(request.createdAt) <= expiry,
              request.createdAt.timeIntervalSince(now) <= futureTolerance else {
            throw LiteRightError.requestExpired
        }
        if request.action == .toggleHiddenFiles {
            guard request.directoryPath == nil else { throw LiteRightError.invalidDirectory }
        } else {
            guard let path = request.directoryPath,
                  path.hasPrefix("/"), !path.hasPrefix("//"), path != "/",
                  path.utf8.count <= maxDirectoryBytes,
                  !path.contains("\0"),
                  !path.split(separator: "/", omittingEmptySubsequences: false)
                       .contains(where: { $0 == "." || $0 == ".." }) else {
                throw LiteRightError.invalidDirectory
            }
        }
    }
}
