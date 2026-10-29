import Foundation
#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

public struct OperationRequest: Codable, Sendable {
    public let schemaVersion: Int
    public let id: UUID
    public let action: MenuItemID
    public let directoryPath: String?
    public let terminalBundleID: TerminalBundle?
    public let createdAt: Date
    public init(id: UUID = UUID(), action: MenuItemID, directoryPath: String?, terminalBundleID: TerminalBundle?, createdAt: Date = Date()) {
        schemaVersion = 1; self.id = id; self.action = action
        self.directoryPath = directoryPath; self.terminalBundleID = terminalBundleID; self.createdAt = createdAt
    }
}

public final class RequestStore {
    private let directory: URL
    private let ttl: TimeInterval = 60
    public convenience init(appGroupIdentifier: String = SharedPreferences.suiteName) throws {
        guard let base = FileManager.default.containerURLForLiteRightGroup(identifier: appGroupIdentifier) else {
            throw LiteRightError.requestUnavailable
        }
        try self.init(baseDirectory: base.appendingPathComponent("Requests", isDirectory: true))
    }
    public init(baseDirectory: URL) throws {
        directory = baseDirectory
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true,
                                                attributes: [.posixPermissions: 0o700])
    }
    private func url(_ id: UUID, _ status: String) -> URL {
        directory.appendingPathComponent("\(id.uuidString).\(status).json")
    }
    public func save(_ request: OperationRequest) throws {
        // MenuItemID is a closed Codable enum: only the five known actions can be decoded.
        // Every Finder menu action is dispatched to the native host outside the sandbox.
        let payload = try JSONEncoder().encode(request)
        let pending = url(request.id, "pending")
        let tmp = directory.appendingPathComponent("\(UUID().uuidString).tmp")
        let fd = open(tmp.path, O_CREAT | O_EXCL | O_WRONLY | O_CLOEXEC, 0o600)
        guard fd >= 0 else { throw LiteRightError.posix(errno) }
        defer { try? FileManager.default.removeItem(at: tmp) }
        var writeError: Int32? = nil
        payload.withUnsafeBytes { bytes in
            var offset = 0
            while offset < bytes.count {
                let result = write(fd, bytes.baseAddress!.advanced(by: offset), bytes.count - offset)
                if result < 0 { if errno == EINTR { continue }; writeError = errno; break }
                if result == 0 { writeError = EIO; break }
                offset += result
            }
        }
        _ = close(fd)
        if let writeError { throw LiteRightError.posix(writeError) }
        // UUID is random, but never overwrite a previously saved request.
        guard !FileManager.default.fileExists(atPath: pending.path) else { throw LiteRightError.requestAlreadyProcessed }
        try FileManager.default.moveItem(at: tmp, to: pending)
    }
    public func claim(id: UUID) throws -> OperationRequest {
        let pending = url(id, "pending")
        let processing = url(id, "processing")
        guard FileManager.default.fileExists(atPath: pending.path) else { throw LiteRightError.requestAlreadyProcessed }
        do { try FileManager.default.moveItem(at: pending, to: processing) }
        catch { throw LiteRightError.requestAlreadyProcessed }
        let request = try JSONDecoder().decode(OperationRequest.self, from: Data(contentsOf: processing))
        guard request.schemaVersion == 1, request.id == id else {
            throw LiteRightError.unsupportedAction
        }
        guard request.createdAt.timeIntervalSinceNow <= 5,
              Date().timeIntervalSince(request.createdAt) <= ttl else { throw LiteRightError.requestExpired }
        return request
    }
    public func complete(id: UUID) throws {
        try? FileManager.default.removeItem(at: url(id, "processing"))
    }
}

private extension FileManager {
    func containerURLForLiteRightGroup(identifier: String) -> URL? {
        #if os(macOS)
        return containerURL(forSecurityApplicationGroupIdentifier: identifier)
        #else
        return nil
        #endif
    }
}
