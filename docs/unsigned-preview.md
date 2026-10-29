# LiteRight — macOS 27 开发者测试版（未公证）

> **这是面向开发者的测试安装包，不是正式发布版。** 仅支持 macOS 27 Apple Silicon（arm64）。应用及 Finder Sync 扩展采用**临时 ad-hoc 代码签名**，没有 Apple Developer ID 签名，也没有 Apple 公证；该签名不意味着来源可信。

## 安装方式

1. 在本次 GitHub Release 的 Assets 中下载 `.dmg`（或 `.zip`）以及 `SHA256SUMS.txt`。推荐一并下载两个安装包，以便完整校验。
2. 在下载目录打开终端，执行 `shasum -a 256 -c SHA256SUMS.txt`；确认文件与清单匹配。校验值仅用于防止文件传输/存放错误，不能替代开发者身份验证。
3. 使用 DMG：打开磁盘映像，把 `LiteRight.app` 拖到「应用程序」文件夹；使用 ZIP：解压后把 `LiteRight.app` 移入「应用程序」文件夹。
4. 尝试正常启动。若 macOS 显示开发者身份不明或无法检查应用，在**确认文件来自可信的项目仓库**后打开「系统设置 → 隐私与安全性」，在下方选择「仍要打开」，按照系统提示再次确认。按钮通常需要先尝试打开应用后才会出现。
5. **不要**关闭 SIP、全局禁用 Gatekeeper、批量移除隔离属性，或通过覆盖签名的命令强行让扩展运行。若系统仍明确拒绝启动，记录错误并报告，不要尝试绕过系统的恶意软件拦截。

Apple 官方说明：[在 Mac 上安全地打开 App](https://support.apple.com/zh-cn/102445)。

## 本包可以验证什么？

可以尝试验证 LiteRight 的应用启动、设置界面、菜单栏图标、界面配置等无需真实共享扩展权限的功能。GitHub Actions 的构建和 GUI 测试是自动化证据，但开发者电脑仍需实际观察。

**不能视为已通过的项目：** Finder Sync 是否在系统设置中启用、Finder 右键菜单是否出现、`group.com.wuhunyu.literight` 的跨进程 App Group 读写、通过 Finder 扩展触发的终端和隐藏文件操作。当前 `group.` 前缀 App Group 在新版 macOS 上还可能需要由相同 Apple Developer Team 签名并授权（以及对应 provisioning profile）。用户选择「仍要打开」只处理 Gatekeeper 的应用打开限制，**不会替代这些权限**。

完整 Finder Sync 功能验收仍属于 [Issue #3](https://github.com/wuhunyu/lite-right/issues/3)，需使用正确的开发者签名与 [签名实机测试指南](https://github.com/wuhunyu/lite-right/blob/main/docs/finder-real-machine-acceptance.md)。正式发布状态仍是 **No-Go**。

## 下载与版本规则

- GitHub Actions → **LiteRight macOS unnotarized developer preview**：可下载本次构建的 ZIP、DMG 和校验文件 Artifact（保留 30 天）。
- 以 `preview-v*` 开头的 Git 标签会发布 GitHub **Pre-release**，附带相同文件。
- 只有明确标注 `[publish-preview]` 的 `main` 提交才会自动生成一次按提交 SHA 命名的 Pre-release；普通 main 提交只上传 Actions 构建产物，避免生成大量 Release。
- 无需在 GitHub Actions 中配置 Apple 证书或公证密钥。若以后要进行完整 Finder Sync 验收，必须另建有开发者签名的构建/验收流程。
