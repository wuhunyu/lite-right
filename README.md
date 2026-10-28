# LiteRight

LiteRight 是原生 Swift / SwiftUI + AppKit 的轻量 macOS Finder 右键工具，目标平台 macOS 27。

## 功能

- Finder 右键：新建 TXT、Markdown、切换显示隐藏文件、打开终端、复制当前目录路径。
- 五个 LiteRight 菜单支持排序和独立显示/隐藏，不更改 Finder 系统菜单。
- Terminal.app / iTerm2 自动检测；Shell 单独检测 Bash、Zsh、Fish，缺失选项置灰。
- 菜单栏和 Dock 图标可设置显隐；登录启动由 ServiceManagement 管理。
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
