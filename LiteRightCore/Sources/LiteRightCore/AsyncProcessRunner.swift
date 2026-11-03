import Foundation
import Darwin

public struct AsyncProcessResult: Sendable {
    public let terminationStatus: Int32
    public let standardError: String
}

public enum AsyncProcessRunnerError: Error, Equatable {
    case timedOut
}

/// Runs a child process without blocking the caller's executor and bounds its lifetime.
public enum AsyncProcessRunner {
    public static func run(
        executableURL: URL,
        arguments: [String],
        timeout: Duration
    ) async throws -> AsyncProcessResult {
        try await withCheckedThrowingContinuation { continuation in
            Task {
                await ProcessWaitState.launch(
                    executableURL: executableURL,
                    arguments: arguments,
                    timeout: timeout,
                    continuation: continuation
                )
            }
        }
    }
}

private actor ProcessWaitState {
    private var process: Process?
    private var stderrHandle: FileHandle?
    private var stderrURL: URL?
    private var continuation: CheckedContinuation<AsyncProcessResult, Error>?
    private var timeoutTask: Task<Void, Never>?
    private var forceKillTask: Task<Void, Never>?
    private var didTimeOut = false

    static func launch(
        executableURL: URL,
        arguments: [String],
        timeout: Duration,
        continuation: CheckedContinuation<AsyncProcessResult, Error>
    ) async {
        let state = ProcessWaitState()
        await state.launchProcess(
            executableURL: executableURL,
            arguments: arguments,
            timeout: timeout,
            continuation: continuation
        )
    }

    private func launchProcess(
        executableURL: URL,
        arguments: [String],
        timeout: Duration,
        continuation: CheckedContinuation<AsyncProcessResult, Error>
    ) {
        let process = Process()
        process.executableURL = executableURL
        process.arguments = arguments

        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("LiteRight-\(UUID().uuidString).stderr")
        guard FileManager.default.createFile(
            atPath: outputURL.path,
            contents: Data(),
            attributes: [.posixPermissions: 0o600]
        ), let outputHandle = try? FileHandle(forWritingTo: outputURL) else {
            continuation.resume(throwing: CocoaError(.fileWriteUnknown))
            return
        }

        self.process = process
        self.stderrHandle = outputHandle
        self.stderrURL = outputURL
        self.continuation = continuation
        process.standardError = outputHandle
        process.terminationHandler = { [weak self] _ in
            guard let self else { return }
            Task { await self.processDidTerminate() }
        }

        do {
            try process.run()
        } catch {
            process.terminationHandler = nil
            try? outputHandle.close()
            try? FileManager.default.removeItem(at: outputURL)
            self.process = nil
            self.stderrHandle = nil
            self.stderrURL = nil
            self.continuation = nil
            continuation.resume(throwing: error)
            return
        }

        timeoutTask = Task { [weak self] in
            do { try await Task.sleep(for: timeout) } catch { return }
            await self?.timeoutProcess()
        }
    }

    private func timeoutProcess() {
        guard let process, process.isRunning else { return }
        didTimeOut = true
        process.terminate()
        forceKillTask = Task { [weak self] in
            do { try await Task.sleep(for: .seconds(1)) } catch { return }
            await self?.forceTerminateIfNeeded()
        }
    }

    private func forceTerminateIfNeeded() {
        guard let process, process.isRunning else { return }
        _ = Darwin.kill(process.processIdentifier, SIGKILL)
    }

    private func processDidTerminate() {
        timeoutTask?.cancel()
        forceKillTask?.cancel()

        try? stderrHandle?.close()
        let errorText = stderrURL.flatMap { try? Data(contentsOf: $0) }
            .flatMap { String(data: $0, encoding: .utf8) } ?? ""
        if let stderrURL { try? FileManager.default.removeItem(at: stderrURL) }

        guard let continuation else { return }
        self.continuation = nil
        if didTimeOut {
            continuation.resume(throwing: AsyncProcessRunnerError.timedOut)
        } else if let process {
            continuation.resume(returning: AsyncProcessResult(
                terminationStatus: process.terminationStatus,
                standardError: errorText
            ))
        }
        self.process = nil
        self.stderrHandle = nil
        self.stderrURL = nil
    }
}
