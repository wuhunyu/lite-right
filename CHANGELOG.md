# Changelog

## Unreleased
- Initialize native Swift macOS app and Finder Sync extension source.
- Add menu customization, shell/terminal detection, atomic file operations, short-lived request bridge, and macOS CI.
- Fix the macOS 27 SwiftUI startup crash by replacing `MenuBarExtra` with a native AppKit `NSStatusItem`; 5/5 hosted GUI smoke tests pass.
- P0 signed Finder Sync compatibility and release acceptance still pending.
