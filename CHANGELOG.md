# 2026-11-03 — v1.0.0 社区正式发布（未公证）

- 版本渠道设为 `release`，系统版本与关于界面统一为 `1.0.0`；此前预览构建继续显示 `1.0.0-preview`。
- 发布代码基于 PR #26：原生 LiteRight 标题栏、与顶部齐平的侧边栏、修复右侧内容遮挡、静默执行 Finder 右键操作、主动打开设置。
- GitHub Release 包含 Apple Silicon 的 ad-hoc 签名 ZIP/DMG 与 SHA-256 清单。明确说明 **没有 Apple Developer ID 签名、未经 Apple 公证**，可能被 macOS 安全保护阻止。
- 保留未公证版本所需、受验证范围约束的本地 URL 操作通道；该通道无法认证本机 URL 调用方，提醒用户评估风险。
- CI 核心、编译、打包与主要 UI 测试已覆盖；托管 macOS 的菜单显隐持久化 GUI 测试仍存在未确认的失败，且真实 Finder Sync 签名授权未完成验收。

# 2026-11-03 — 1.0.0-preview product polish

- 菜单栏使用 LiteRight 品牌图形的单色模板资源替代通用 SF Symbol。
- 移除「权限管理」独立页面，将 Finder 扩展系统状态与管理入口整合进「通用」。
- 继续保留 Terminal/iTerm2 的 AppleScript 自动化支持，不再展示无法实际验证的终端自动化状态。
- 用户版本显示为 `1.0.0-preview`，Apple 营销版本为 `1.0.0`，预览构建号由 CI 设置。
- 诊断摘要新增真实架构、Finder 状态、通信方式与监控目录数量；不复制完整路径。

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
