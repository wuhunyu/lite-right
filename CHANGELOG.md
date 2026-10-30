# Changelog

## 2026-10-30 — macOS developer preview (Finder menu synchronization)

- Merge #20 into `main`: reload the Finder menu's visibility, order and chosen Terminal/iTerm2 label from updated settings in the unsigned preview.
- Switch hidden-file toggling from Finder restart/AppleScript to Finder's Command-Shift-Period keystroke through native CoreGraphics keyboard events.
- Request/check accessibility input-event authorization, activate Finder before posting the shortcut, and report unverified state changes.
- Add keyboard event sequence tests, dynamic hidden-files menu title and icons, and Finder test instructions.
- **Preview limitation:** macOS CI checks compilation and package integrity, not actual Finder right-click handling or cross-process sandbox notifications. Real-device acceptance remains open in issues #3, #12, #13 and #19.
- Developer preview packages are ad-hoc signed and unnotarized; use the instructions in `docs/unsigned-preview.md`.

## Unreleased
- Initialize native Swift macOS app and Finder Sync extension source.
- Add menu customization, shell/terminal detection, atomic file operations, short-lived request bridge, and macOS CI.
- Fix the macOS 27 SwiftUI startup crash by replacing `MenuBarExtra` with a native AppKit `NSStatusItem`; 5/5 hosted GUI smoke tests pass.
- P0 signed Finder Sync compatibility and release acceptance still pending.
