import Foundation

public enum TargetResolver {
    public static func resolve(containerURL: URL?, selectedItemURLs: [URL]) -> ResolvedTarget {
        guard !selectedItemURLs.isEmpty else {
            guard let containerURL, let directory = validatedDirectory(containerURL) else {
                return .init(directoryURL: nil, sourceKind: .unsupported)
            }
            return .init(directoryURL: directory, sourceKind: .blankArea)
        }

        var directories: [URL] = []
        var folderOnly = false
        for item in selectedItemURLs {
            guard item.isFileURL,
                  let attrs = try? item.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey, .isPackageKey]),
                  attrs.isDirectory != nil || attrs.isSymbolicLink == true else {
                return .init(directoryURL: nil, sourceKind: .unsupported)
            }
            let folder = attrs.isDirectory == true && attrs.isSymbolicLink != true &&
                         attrs.isPackage != true && item.pathExtension.lowercased() != "app"
            folderOnly = folder
            guard let directory = validatedDirectory(folder ? item : item.deletingLastPathComponent()) else {
                return .init(directoryURL: nil, sourceKind: .unsupported)
            }
            directories.append(directory)
        }
        guard let first = directories.first else { return .init(directoryURL: nil, sourceKind: .unsupported) }
        guard directories.dropFirst().allSatisfy({ $0 == first }) else {
            return .init(directoryURL: nil, sourceKind: .mixed)
        }
        return .init(
            directoryURL: first,
            sourceKind: selectedItemURLs.count > 1 ? .mixed : (folderOnly ? .folder : .files),
            // Only a single selected non-folder changes copy semantics.
            // Creation and terminal actions still use the parent directory.
            copyPathURL: selectedItemURLs.count == 1 && !folderOnly
                ? selectedItemURLs[0].standardizedFileURL : first
        )
    }

    /// Accept an existing regular file or directory without resolving the
    /// selected item's displayed path to its parent. Symlink-specific behavior
    /// is intentionally outside this feature.
    public static func validatedCopyTarget(_ url: URL) -> URL? {
        guard url.isFileURL else { return nil }
        let normalized = url.standardizedFileURL
        guard let values = try? normalized.resourceValues(
            forKeys: [.isDirectoryKey, .isRegularFileKey]
        ), values.isDirectory == true || values.isRegularFile == true else { return nil }
        return normalized
    }

    public static func validatedDirectory(_ directory: URL) -> URL? {
        guard directory.isFileURL else { return nil }
        let normalized = directory.standardizedFileURL.resolvingSymlinksInPath()
        guard let values = try? normalized.resourceValues(forKeys: [.isDirectoryKey]), values.isDirectory == true else { return nil }
        return normalized
    }
}
