# LiteRight

LiteRight 是原生 Swift / SwiftUI + AppKit 的轻量 macOS Finder 右键工具，目标平台 macOS 27。

## 功能

- Finder 右键：新建 TXT、Markdown、切换显示隐藏文件、打开终端、复制当前目录路径。
- 五个 LiteRight 菜单支持排序和独立显示/隐藏，不更改 Finder 系统菜单。
- Terminal.app / iTerm2 自动检测；Shell 单独检测 Bash、Zsh、Fish，缺失选项置灰。
- 菜单栏和 Dock 图标可设置显隐；登录启动由 ServiceManagement 管理。
- 「通用」设置支持添加、移除和刷新 Finder 监控目录；「权限管理」可查看系统报告的扩展启用状态及主应用 App Group 可访问情况（均不能替代实际 Finder 右键验收）。
- 原子文件创建 O_EXCL，避免覆盖与并发重复命名；本地 App Group 配置和短期请求桥接。

## 构建

需要支持 macOS 27 SDK 的 Xcode、Swift 6 和 XcodeGen。

```sh
brew install xcodegen
swift test --package-path LiteRightCore
python3 -m venv .icon-venv
.icon-venv/bin/python -m pip install pillow cairosvg
.icon-venv/bin/python tools/export-icons.py
xcodegen generate
xcodebuild -project LiteRight.xcodeproj -scheme LiteRight -configuration Debug CODE_SIGNING_ALLOWED=NO build
```

App Icon PNG 由已提交的 SVG 矢量源码在构建时生成，不要求运行时安装 Python。构建需要在已支持 xcode-27 的 macOS runner / 对应 macOS 上完成。CI 自动执行上述流程。

为了安装并启用 Finder Sync，需要用自己的 Apple Developer Team 对 App 与 Extension 一致签名，并确认 App Group 权限。未签名的 CI 编译仅用于查错。

## 当前阶段

这是代码实现的首轮版本，**不是已完成真实 Finder 兼容性验收的正式发布**。Finder Sync 官方监控目录有覆盖限制；扩展能否在所有期望位置以一级菜单显示、Terminal 是否不受 Tab 偏好影响而新建窗口、授权弹窗和 macOS 27 玻璃界面，必须在真正的 macOS 27 机器上测试。请参阅 docs/p0-matrix.md。

默认监控主目录，不保证搜索结果、最近使用、iCloud、外接盘和网络共享的菜单可用；若 P0 未通过，禁止宣称可发布。隐藏文件的默认切换影响整个 Finder，并在确认后重启 Finder。

运行不需要联网、root、关闭 SIP、Electron 或 WebView。仓库暂不附加开源许可证。

## 自动化验证

GitHub Actions 在 macOS 27 Runner 执行真实磁盘集成测试、编译应用及 Finder 扩展、验证生成的 App Bundle，并尝试启动原生 GUI/XCUITest；详见 [CI 运行时测试](docs/ci-runtime-tests.md)。图形会话与 Finder 扩展授权受托管环境限制，因此 UI 检查暂不作为合并门禁。

**启动崩溃已修复：** [Issue #4](https://github.com/wuhunyu/lite-right/issues/4) 中由 SwiftUI `MenuBarExtra` 引发的 macOS 27 启动问题已改由原生 AppKit `NSStatusItem` 实现菜单栏，2026-10-29 的 [CI #40806618329](https://github.com/wuhunyu/lite-right/actions/runs/40806618329) 中 Required 检查和 **5/5 原生 GUI 测试全部通过**。但受托管 CI 环境限制，**Finder 右键菜单、系统授权与签名安装仍未通过实机验收**，详见 [Issue #3](https://github.com/wuhunyu/lite-right/issues/3)。

## Issue #3 签名实机验收

Finder Sync 的右键菜单作用域由已登记监控目录决定，扩展无法无条件覆盖所有 Finder 位置。动态监控目录与右键目标判定已经纳入 macOS 自动化测试；签名、公证和真实 Finder 菜单仍需要实机验证。

请使用 [Finder Sync 签名安装与实机验收指南](docs/finder-real-machine-acceptance.md)，以 `swift ci/verify-signed-app.swift /path/to/LiteRight.app` 验证主应用及扩展签名、TeamIdentifier 与 App Group，再将截图和测试结果填写进 [P0 验收矩阵](docs/p0-matrix.md)。**未获得签名实机证据前，项目仍为 No-Go。**
