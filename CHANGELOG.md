# Changelog

## 2026-11-03 — 当前版本：移除隐藏文件功能，完成复制绝对路径链路

- 按产品范围调整，删除显示/隐藏文件右键菜单、执行逻辑、辅助功能设置及测试；此前模拟快捷键和重启兼容方案不再提供。
- 兼容旧版配置中的 `toggleHiddenFiles`，迁移时只丢弃该菜单条目，保留其余用户排序、显隐及终端首选项。
- 复制绝对路径：空白处复制当前目录、选中目录复制目录、选中单文件复制文件完整路径，支持中文和空格；新建文件和终端操作仍使用正确的目录。
- 增加真实 macOS GUI 预览版剪贴板链路测试；Finder 签名实机交互仍属 #3 的验收范围。


## 2026-11-03 — Finder hidden-file shortcut PID routing preview

- Merge PR #21: post all six CoreGraphics Command-Shift-Period physical events directly to the Finder process PID rather than the global HID event tap, reducing focus timing dependency from URL activation.
- TDD: expected RED on the missing PID delivery API, then macOS Swift tests and arm64 preview packaging passed. Added tests for correct event destination and invalid PID.
- Existing permission checks and Finder state-change verification remain. This is a developer preview, **not** real Finder interaction acceptance: #3, #13, #19 stay open pending user-machine verification.
- [publish-preview] is used for this checkpoint so the matching test package can be installed for real-device verification.


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
