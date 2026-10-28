import Foundation
#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

public enum FileTemplateKind: Sendable { case text, markdown
    public var ext: String { self == .text ? "txt" : "md" }
}

public enum AtomicFileCreator {
    public static func createFile(in directoryURL: URL, template: FileTemplateKind) throws -> URL {
        guard let directory = TargetResolver.validatedDirectory(directoryURL) else { throw LiteRightError.invalidDirectory }
        for index in 0..<10_000 {
            let stem = index == 0 ? "untitled" : (index == 1 ? "untitled_copy" : "untitled_copy_\(index)")
            let destination = directory.appendingPathComponent("\(stem).\(template.ext)")
            let fd = open(destination.path, O_CREAT | O_EXCL | O_WRONLY | O_CLOEXEC | O_NOFOLLOW, 0o644)
            if fd >= 0 {
                _ = close(fd)
                return destination
            }
            let code = errno
            switch code {
            case EEXIST: continue
            case EACCES, EPERM: throw LiteRightError.permissionDenied
            case ENOSPC, EDQUOT: throw LiteRightError.diskFull
            case EROFS: throw LiteRightError.readOnlyVolume
            case ENOENT, ENOTDIR: throw LiteRightError.invalidDirectory
            default: throw LiteRightError.posix(code)
            }
        }
        throw LiteRightError.tooManyNameConflicts
    }
}
