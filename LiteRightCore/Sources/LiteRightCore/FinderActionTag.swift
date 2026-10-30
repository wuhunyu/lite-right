import Foundation

/// Finder Sync copies NSMenuItem values across process boundaries.
/// Unlike representedObject, NSMenuItem.tag is supported for Finder Sync menus
/// (macOS 10.11+). Encode the menu context as well as the action so handlers
/// can obtain the correct target from FIFinderSyncController at click time.
public enum FinderActionTag {
    public static func tag(for action: MenuItemID, context: FinderMenuContext) -> Int? {
        let contextBase: Int
        switch context {
        case .items: contextBase = 100
        case .container: contextBase = 200
        case .sidebar: contextBase = 300
        case .toolbar: return nil
        }
        let actionCode: Int
        switch action {
        case .newText: actionCode = 1
        case .newMarkdown: actionCode = 2
        case .toggleHiddenFiles: actionCode = 3
        case .openInTerminal: actionCode = 4
        case .copyDirectoryPath: actionCode = 5
        }
        return contextBase + actionCode
    }

    public static func resolve(tag: Int) -> (action: MenuItemID, context: FinderMenuContext)? {
        let context: FinderMenuContext
        switch tag / 100 {
        case 1: context = .items
        case 2: context = .container
        case 3: context = .sidebar
        default: return nil
        }
        let action: MenuItemID
        switch tag % 100 {
        case 1: action = .newText
        case 2: action = .newMarkdown
        case 3: action = .toggleHiddenFiles
        case 4: action = .openInTerminal
        case 5: action = .copyDirectoryPath
        default: return nil
        }
        return (action: action, context: context)
    }
}
