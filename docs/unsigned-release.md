# LiteRight 1.0.0 — macOS ARM64 正式版本（未经 Apple 公证）

> **安装前请阅读。** 这是 LiteRight 首个 GitHub 正式版本（非 Pre-release），但所附 macOS 程序采用 **ad-hoc 临时签名，未取得 Apple Developer ID 签名，也未经过 Apple 公证**。macOS 可能阻止首次打开。**仅在你认可发布来源、理解以下权限和安全限制后自行安装。** GitHub Release 的“正式”分类不代表经过 Apple 安全审核。

**平台：** macOS 27 及更高版本，Apple Silicon（arm64）。**版本：** 1.0.0。主应用和 Finder Sync 扩展一起打包。

## 本版功能

- 在 Finder 中新建 TXT、Markdown 文件；在 Terminal.app / iTerm2 中打开当前目录；复制文件或目录的绝对路径。
- 四项 Finder 菜单独立显隐、排序与终端选择；设置窗口、菜单栏入口、Dock 入口。
- Finder 右键操作静默执行，不自动弹出设置窗口；主动启动 LiteRight 才显示设置。
- LiteRight 品牌菜单栏图标和原生 macOS 标题栏、侧边栏布局。

## 下载、校验和安装

1. 从本项目的 **GitHub Releases → v1.0.0 → Assets** 下载 `.dmg` 或 `.zip`，以及 `SHA256SUMS.txt`。校验时应下载清单中对应的两个文件，或只核对自己下载的文件对应行。
2. 在终端运行 `shasum -a 256 LiteRight-v1.0.0-macos-arm64-adhoc.dmg`，并与 `SHA256SUMS.txt` 中相同文件名对应的 SHA-256 值核对。哈希一致只能证明字节与清单一致，不能证明开发者身份。
3. 打开 DMG，将 LiteRight.app 拖入「应用程序」（或解压 ZIP 并复制到该目录）。为避免系统绑定到旧的 Finder 扩展，请移走其他位置重复安装的 LiteRight.app。
4. 第一次启动如被 macOS 拒绝，在确认来源后进入 **系统设置 → 隐私与安全性 → 仍要打开**，按系统提示允许。不要关闭 SIP、全局关闭 Gatekeeper，也不要忽视系统的恶意软件检测警告。
5. 如果 Finder 右键菜单未出现，请到 **系统设置 → 通用 → 登录项与扩展 → Finder 扩展** 检查 LiteRight 是否启用。仅手动允许打开 App **不会**自动授予 Finder 扩展权限。

Apple 官方说明：[在 Mac 上安全地打开 App](https://support.apple.com/zh-cn/102445)。

## 风险、权限与已知限制

**签名和授权。** 该二进制缺少 Apple Developer ID 和公证凭据，无法保证跨进程 App Group 权限获得授权。Finder Sync 扩展的注册、实际显示和右键执行依赖系统授权、监控目录和本机环境；不能因为程序启动成功就认为扩展已通过完整验收。

**本地 URL 通信。** 为让未公证的 ad-hoc 程序仍可在本地执行 Finder 操作，此安装包使用带校验和限制的 `lite-right://run` 本地 URL 操作通道。其他本机程序也可能请求这个 URL，调用来源**无法进行可靠身份认证**。实现限制固定操作、有效期、重复请求、目录范围及请求大小，但仍不等同于经过身份认证的 App Group/XPC 通道。因此只建议在信任本机应用及用户会话的环境下使用。

**已知测试缺口。** macOS CI 中新旧窗口行为、文件/路径操作及界面布局检查已通过，但托管 macOS Runner 上的「菜单显隐设置重启持久化」GUI 测试仍未通过（读取测试配置文件返回 nil，尚未明确是否为测试隔离或产品缺陷）。建议安装后亲自更改一次菜单显隐设置、重启 LiteRight 并验证是否保留。真实 Finder 扩展注册/权限与文件右键需要本机检查。

**终端自动化。** 只有用户触发「在终端中打开」后才会通过 AppleScript 控制所选终端；macOS 可能请求自动化权限。请仅授予确认需要的权限。

**不建议忽略安全防护。** 无法正常启动、扩展无效或系统明确报告风险时，请保留系统保护设置并在 [Issues](https://github.com/wuhunyu/lite-right/issues) 反馈。

## 源代码与验证

此 GitHub Release 的 `v1.0.0` 标签指向生成安装包的同一个 `main` 提交；`SHA256SUMS.txt` 由发行构建生成。此版本公开的是源码与未经公证的发布二进制，不是 Apple Developer ID 认证产品。
