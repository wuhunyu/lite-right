import Foundation

public enum FinderHiddenFilesState {
    /// Finder may refuse this preference read in a sandbox. Unknown is not "hidden".
    public static func isShowingHiddenFiles() -> Bool? {
        let value = CFPreferencesCopyAppValue(
            "AppleShowAllFiles" as CFString,
            "com.apple.finder" as CFString
        )
        if let number = value as? NSNumber {
            return number.boolValue
        }
        if let text = value as? String {
            switch text.lowercased() {
            case "true", "yes", "1": return true
            case "false", "no", "0": return false
            default: break
            }
        }
        return nil
    }

    public static func menuPresentation(showing: Bool?) -> (title: String, symbol: String) {
        switch showing {
        case .some(true): return ("隐藏隐藏文件", "eye.slash")
        case .some(false): return ("显示隐藏文件", "eye")
        case .none: return ("切换隐藏文件显示", "eye")
        }
    }
}
