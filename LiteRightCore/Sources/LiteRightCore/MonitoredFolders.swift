import Foundation

/// Pure path rules for Finder Sync's explicitly managed directory set.
/// Persist unavailable volume paths so re-mounting does not lose user choices.
public enum MonitoredFolders {
    public static let didChangeNotification = "com.wuhunyu.literight.monitored-folders-changed"

    /// Stable order preserves the order shown by the native settings panel.
    /// Do not register filesystem root; Finder Sync is not a system-wide menu injector.
    public static func normalize(_ paths: [String]) -> [String] {
        var seen = Set<String>()
        var result: [String] = []
        for path in paths where path.hasPrefix("/") {
            let standardized = URL(fileURLWithPath: path, isDirectory: true).standardizedFileURL.path
            guard standardized != "/", seen.insert(standardized).inserted else { continue }
            result.append(standardized)
        }
        return result
    }

    /// The Finder extension registers only existing, readable directories.
    /// An ancestor watch already covers its descendants; register each active root once.
    public static func activeDirectoryURLs(_ paths: [String]) -> Set<URL> {
        let available = Set(normalize(paths).compactMap { path in
            TargetResolver.validatedDirectory(URL(fileURLWithPath: path, isDirectory: true))
        })
        return Set(available.filter { candidate in
            !available.contains { ancestor in
                ancestor != candidate && candidate.path.hasPrefix(ancestor.path + "/")
            }
        })
    }
}
