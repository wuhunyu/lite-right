import Foundation

/// Testable translation from Finder menu kinds to an operation directory.
/// Finder controls where/when the extension is offered; this never guesses $HOME.
public enum FinderMenuContext: Sendable {
    case items, container, sidebar, toolbar
}

public enum FinderMenuTarget {
    public static func resolve(
        context: FinderMenuContext,
        targetedURL: URL?,
        selectedItemURLs: [URL]?
    ) -> ResolvedTarget {
        switch context {
        case .container:
            return TargetResolver.resolve(containerURL: targetedURL, selectedItemURLs: [])
        case .items:
            let selected = selectedItemURLs ?? []
            let clicked = selected.isEmpty ? targetedURL.map { [$0] } ?? [] : selected
            return TargetResolver.resolve(containerURL: nil, selectedItemURLs: clicked)
        case .sidebar:
            return TargetResolver.resolve(containerURL: nil, selectedItemURLs: targetedURL.map { [$0] } ?? [])
        case .toolbar:
            return ResolvedTarget(directoryURL: nil, sourceKind: .unsupported)
        }
    }
}
