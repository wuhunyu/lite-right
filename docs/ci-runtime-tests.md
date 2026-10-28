# macOS CI 运行时测试 — Phase 2

GitHub Actions `xcode-27` 使用真实的 macOS 27 Runner，不是模拟 macOS API。

## 必须通过的检查（required）

- SwiftPM 测试：纯逻辑 + **实际系统临时目录**中的 TXT/Markdown 原子创建、文件冲突不覆盖、符号链接和 Unicode 路径、Shell 可执行性。
- `xcodebuild build-for-testing`：主程序、Finder Sync、XCUITest runner 编译。
- `ci/verify-app-bundle.swift`：直接读取产物 Info.plist、可执行文件、嵌入 `.appex`、Finder Sync 扩展点、Deep Link、AppIcon Assets.car。
- 失败时上传 Swift、Xcode、bundle 结构校验日志；不因上传失败而隐瞒构建失败。

## 实验性 GUI 检查（非门禁）

- XCUITest **尝试真实启动** SwiftUI App，并检查设置窗口和 5 项菜单。
- 检测 Runner GUI 会话，并尝试 `pluginkit` 注册临时 Finder 扩展。
- 记录 `.xcresult`（XCUITest 自动附件/失败截图）、系统诊断、UI 和 pluginkit 日志。
- 即使这组作业因为授权、签名或 WindowServer 失败，也不能记为「Finder 已通过」。实际执行结果在该作业里明确显示。

不能在无审批情形中伪造 TCC 权限，不能把 `pluginkit` 出现在列表中等同于 Finder 右键菜单可见。

## 待实机验证的 P0

macOS 27 登录桌面、使用 Apple Developer Team 签名的 App 与 Finder Sync（包括共享 App Group 权限）；按 `docs/p0-matrix.md` 验证文件夹/多选/搜索/iCloud/外接卷、窗口与权限。

## 本地运行

```sh
swift test --package-path LiteRightCore
brew install xcodegen
python3 -m venv .icon-venv
.icon-venv/bin/python -m pip install pillow cairosvg
.icon-venv/bin/python tools/export-icons.py
xcodegen generate
xcodebuild -project LiteRight.xcodeproj -scheme LiteRight -configuration Debug -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO build-for-testing
```

XCUITest 需登录图形会话：

```sh
xcodebuild -project LiteRight.xcodeproj -scheme LiteRight -configuration Debug -destination 'platform=macOS' -only-testing:LiteRightUITests CODE_SIGNING_ALLOWED=NO test
```
