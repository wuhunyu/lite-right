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

## 2026-10-28 实测结果

- Required macOS 27 检查（27 项 Swift 测试、实际文件系统、完整 `build-for-testing`、App Bundle/appex 结构）**全部通过**。详见 [Run #40680739250](https://github.com/wuhunyu/lite-right/actions/runs/40680739250)。
- 实验性 XCUITest **0/2 通过，实际失败**：App 在 macOS 27.0.1/Xcode 27.1 Runner 下出现 SIGSEGV 栈溢出，另一测试无法加载 Accessibility。
- `pluginkit -a` 命令成功返回，**不等同于 Finder 右键菜单出现**。
- 启动崩溃追踪：[Issue #4](https://github.com/wuhunyu/lite-right/issues/4)；签名 Finder 真机测试：[Issue #3](https://github.com/wuhunyu/lite-right/issues/3)。
- 因测试目前尚不稳定，GUI job 使用 `continue-on-error`，**工作流绿色不等于 GUI 绿色**，应查看两个 job 的独立结论。P0 仍为 No-Go。

## 2026-10-29 启动崩溃修复与复测

- 解析 2026-10-28 XCUITest .xcresult 的崩溃报告：主线程发生 SwiftUI AppGraph/窗口/菜单图更新递归，触及栈保护区（SIGSEGV）。
- Debug 隔离实验（[Run #40805705752](https://github.com/wuhunyu/lite-right/actions/runs/40805705752)）：禁用菜单栏插入的最小窗口与完整设置窗口均通过；启用 SwiftUI `MenuBarExtra` 的两个启动测试失败，原始设置窗口测试崩溃。
- 使用原生 AppKit `NSStatusItem` 替换 SwiftUI `MenuBarExtra`，保留原生菜单项、图标显隐和 SwiftUI 设置窗口。
- 修复后 [Run #40806618329](https://github.com/wuhunyu/lite-right/actions/runs/40806618329)：Required 全通过；XCUITest **5/5 通过、0 失败**，Experimental job 也显示 success。
- 当前 GUI job 仍使用 `continue-on-error`，后续须评估 CI 稳定性；这组通过结果**不等于 Finder 菜单和权限已验收**。正式发布仍受 [Issue #3](https://github.com/wuhunyu/lite-right/issues/3) 阻断。

## Issue #3 的新增自动化（2026-10-29）

- SwiftPM 新增根目录规范化与真实文件系统监控测试：绝对路径去重、`/` 排除、嵌套根目录、离线卷路径保留、Unicode 目录。
- SwiftPM 新增 Finder 上下文目录解析测试：container/items/sidebar/toolbar，选中项父目录、多选不一致、搜索结果项路径。
- XCUITest 覆盖「通用」设置中的「添加监控目录」按钮；不自动弹出系统文件选择框，不写入 CI Runner 的用户配置。
- `ci/verify-signed-app.swift` 属于**实机签名验收**：验证 App 与 Finder appex 都经过有效签名、TeamIdentifier 一致、App Group entitlement 一致。CI 仅做反向测试（未签名 App 必须失败），绝不冒充已具备真实 Apple Developer 签名。
- UI 显示 `FIFinderSyncController.isExtensionEnabled` 与主应用 App Group 容器可访问情况仅作诊断；Finder 实际右键操作另填 [P0 矩阵](p0-matrix.md)。

按 [Finder Sync 签名安装与实机验收指南](finder-real-machine-acceptance.md) 执行含 Apple Developer Team 的本地签名构建及交互测试。
