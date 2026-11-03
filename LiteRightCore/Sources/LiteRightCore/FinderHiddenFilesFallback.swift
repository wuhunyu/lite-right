import Foundation

/// Explicit, opt-in compatibility mode only. A failed synthetic shortcut
/// must never restart Finder or modify its preferences on its own.
public enum FinderHiddenFilesFallback {
    public enum Choice: Sendable {
        case show, hide, cancel
    }

    @discardableResult
    public static func apply(
        _ choice: Choice,
        updatePreference: (Bool) throws -> Void,
        restartFinder: () throws -> Void
    ) throws -> Bool {
        let desired: Bool
        switch choice {
        case .show: desired = true
        case .hide: desired = false
        case .cancel: return false
        }
        try updatePreference(desired)
        try restartFinder()
        return true
    }
}
