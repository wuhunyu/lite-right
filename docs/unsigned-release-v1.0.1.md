# LiteRight 1.0.1 — macOS ARM64 正式版本（未经 Apple 公证）

> **安装前请阅读。** 本版本采用 **ad-hoc 临时签名，未取得 Apple Developer ID 签名，也未经过 Apple 公证**。macOS 可能阻止首次打开。**仅在你认可发布来源、理解以下权限和安全限制后自行安装。** GitHub Release 的“正式”分类不代表经过 Apple 安全审核。

**平台：** macOS 27 及更高版本，Apple Silicon（arm64）。**版本：** 1.0.1。主应用和 Finder Sync 扩展一起打包。

## 本版更新

- 优化设置快照读取、偏好迁移、临时请求去重与清理，以及 Finder 操作的异步协调，减少重复磁盘访问和主线程等待。
- 保持现有 Finder 菜单、设置项、窗口行为和终端操作；增加设置持久化的 GUI 自动化覆盖。
- 继续使用未公证发布构建的本地 `lite-right://run` 操作通道。

## 下载、校验和安装

1. 从本项目的 **GitHub Releases → v1.0.1 → Assets** 下载 `.dmg` 或 `.zip`，以及 `SHA256SUMS.txt`。校验时应下载清单中对应的两个文件，或只核对自己下载的文件对应行。
2. 在终端运行 `shasum -a 256 LiteRight-v1.0.1-macos-arm64-adhoc.dmg`，并与 `SHA256SUMS.txt` 中相同文件名对应的 SHA-256 值核对。哈希一致只能证明字节与清单一致，不能证明开发者身份。
3. 打开 DMG，将 LiteRight.app 拖入「应用程序」（或解压 ZIP 并复制到该目录）。为避免系统绑定到旧的 Finder 扩展，请移走其他位置重复安装的 LiteRight.app。
4. 第一次启动如被 macOS 拒绝，在确认来源后进入 **系统设置 → 隐私与安全 → 仍要打开**，按系统提示允许。不要关闭 SIP、全局关闭 Gatekeeper，也不要忽视系统的恶意软件检测警告。
5. 如果 Finder 右键菜单未出现，请到 **系统设置 → 通用 → 登录项与扩展 → Finder 扩展** 检查 LiteRight 是否启用。仅手动允许打开 App **不会**自动授予 Finder 扩展权限。

Apple 官方说明：[在 Mac 上安全地打开 App](https://support.apple.com/zh-cn/102445)。

## 风险、权限与已知限制

**签名和授权。** 该二进制缺少 Apple Developer ID 和公证凭据，无法保证跨进程 App Group 权限获得授权。Finder Sync 扩展的注册、实际显示和右键执行依赖系统授权、监控目录和本机环境；不能因为程序启动成功就认为扩展已通过完整验收。

**本地 URL 通信。** 为让未公证的 ad-hoc 程序仍可在本地执行 Finder 操作，此安装包使用带校验和限制的 `lite-right://run` 本地 URL 操作通道。其他本机程序也可能请求这个 URL，调用来源**无法进行可靠身份认证**。实现限制固定操作、有效期、重复请求、目录范围及请求大小，但仍不等同于经过身份认证的 App Group/XPC 通道。因此只建议在信任本机应用及用户会话的环境下使用。

**Finder 验收范围。** GitHub macOS Actions 验证了 Swift/Core 测试、应用及扩展构建和 GUI 自动化；用户已验收本版临时构建包。真实 Finder 右键菜单、系统授权、签名安装及 Apple 公证流程仍依赖用户自己的目标机器与 Apple Developer Team，不能由未公证 CI 包代替。

**终端自动化。** 只有用户触发「在终端中打开」后才会通过 AppleScript 控制所选终端；macOS 可能请求自动化权限。请仅授予确认需要的权限。

## 源代码与验证

此 GitHub Release 的 `v1.0.1` 标签指向生成安装包的同一个 `main` 提交；`SHA256SUMS.txt` 由发行构建生成。此版本公开的是源码与未经公证的发布二进制，不是 Apple Developer ID 认证产品。
