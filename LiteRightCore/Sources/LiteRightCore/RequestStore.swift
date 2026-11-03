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
    public var operationTarget: OperationTarget? {
        guard let directoryPath, directoryPath.hasPrefix("/"), !directoryPath.contains("\0") else {
            return nil
        }
        if action == .copyDirectoryPath {
            return .absolutePath(URL(fileURLWithPath: directoryPath).standardizedFileURL)
        }
        return .directory(URL(fileURLWithPath: directoryPath, isDirectory: true).standardizedFileURL)
    }
    public init(id: UUID = UUID(), action: MenuItemID, directoryPath: String?, terminalBundleID: TerminalBundle?, createdAt: Date = Date()) {
        schemaVersion = 1; self.id = id; self.action = action
        self.directoryPath = directoryPath; self.terminalBundleID = terminalBundleID; self.createdAt = createdAt
    }

    /// File copying keeps the selected file path; directory actions use
    /// the resolved directory for both signed and unsigned transports.
    public static func forFinderMenu(
        action: MenuItemID,
        directoryURL: URL?,
        copyPathURL: URL? = nil,
        preferredTerminal: TerminalBundle
    ) -> OperationRequest {
        let requestedPath = action == .copyDirectoryPath
            ? (copyPathURL ?? directoryURL) : directoryURL
        return OperationRequest(
            action: action,
            directoryPath: requestedPath?.path,
            terminalBundleID: action == .openInTerminal ? preferredTerminal : nil
        )
    }
}

public enum OperationTarget: Equatable, Sendable {
    case directory(URL)
    case absolutePath(URL)
}

public final class RequestStore {
    private let directory: URL
    private let ttl: TimeInterval = 60
    private let abandonedProcessingAge: TimeInterval = 24 * 60 * 60
    private let temporaryFileAge: TimeInterval = 10 * 60
    private let cleanupLimit = 128
    private let maximumRequestFileSize = 16 * 1024
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
        _ = cleanupExpiredRequests()
        // MenuItemID is a closed Codable enum: only the four supported actions can be decoded.
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
        _ = cleanupExpiredRequests()
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
        _ = cleanupExpiredRequests()
    }

    /// Reclaims expired pending, abandoned processing, and stale temporary files.
    /// The bounded scan runs only on request activity; no timer or background service is needed.
    @discardableResult
    public func cleanupExpiredRequests(now: Date = Date()) -> Int {
        guard let entries = FileManager.default.enumerator(
            at: directory,
            includingPropertiesForKeys: [.contentModificationDateKey, .isRegularFileKey, .fileSizeKey],
            options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants]
        ) else { return 0 }

        var inspected = 0
        var removed = 0
        while inspected < cleanupLimit, let file = entries.nextObject() as? URL {
            guard let values = try? file.resourceValues(forKeys: [.contentModificationDateKey, .isRegularFileKey, .fileSizeKey]),
                  values.isRegularFile == true,
                  let modified = values.contentModificationDate else { continue }
            inspected += 1

            let name = file.lastPathComponent
            let shouldRemove: Bool
            if name.hasSuffix(".pending.json") {
                if let size = values.fileSize, size <= maximumRequestFileSize,
                   let bytes = try? Data(contentsOf: file),
                   let request = try? JSONDecoder().decode(OperationRequest.self, from: bytes) {
                    let age = now.timeIntervalSince(request.createdAt)
                    shouldRemove = age > ttl || age < -5
                } else {
                    shouldRemove = now.timeIntervalSince(modified) > ttl
                }
            } else if name.hasSuffix(".processing.json") {
                // A host operation may outlive the request's claim TTL. Only
                // reclaim processing files after a day, which indicates a crash.
                shouldRemove = now.timeIntervalSince(modified) > abandonedProcessingAge
            } else if name.hasSuffix(".tmp") {
                shouldRemove = now.timeIntervalSince(modified) > temporaryFileAge
            } else {
                continue
            }

            if shouldRemove, (try? FileManager.default.removeItem(at: file)) != nil {
                removed += 1
            }
        }
        return removed
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
