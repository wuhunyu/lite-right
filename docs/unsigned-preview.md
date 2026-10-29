# LiteRight — macOS 27 开发者测试版（未公证）

> **这是面向开发者的测试安装包，不是正式发布版。** 仅支持 macOS 27 Apple Silicon（arm64）。应用及 Finder Sync 扩展采用**临时 ad-hoc 代码签名**，没有 Apple Developer ID 签名，也没有 Apple 公证；该签名不意味着来源可信。

## 安装方式

1. 在本次 GitHub Release 的 Assets 中下载 `.dmg`（或 `.zip`）以及 `SHA256SUMS.txt`。推荐一并下载两个安装包，以便完整校验。
2. 在下载目录打开终端，执行 `shasum -a 256 -c SHA256SUMS.txt`；确认文件与清单匹配。校验值仅用于防止文件传输/存放错误，不能替代开发者身份验证。
3. 使用 DMG：打开磁盘映像，把 `LiteRight.app` 拖到「应用程序」文件夹；使用 ZIP：解压后把 `LiteRight.app` 移入「应用程序」文件夹。
4. 尝试正常启动。若 macOS 显示开发者身份不明或无法检查应用，在**确认文件来自可信的项目仓库**后打开「系统设置 → 隐私与安全性」，在下方选择「仍要打开」，按照系统提示再次确认。按钮通常需要先尝试打开应用后才会出现。
5. **不要**关闭 SIP、全局禁用 Gatekeeper、批量移除隔离属性，或通过覆盖签名的命令强行让扩展运行。若系统仍明确拒绝启动，记录错误并报告，不要尝试绕过系统的恶意软件拦截。

Apple 官方说明：[在 Mac 上安全地打开 App](https://support.apple.com/zh-cn/102445)。

## Finder 右键菜单缺失：诊断和手动启用

**开发者必须另外确认 Finder Sync 扩展已注册并启用。** 仅允许应用在「隐私与安全性」中打开，不等于 Finder 已加载 `LiteRightFinderExtension.appex`。

本次 DMG 已附带 `diagnose-finder-sync.sh`：在「应用程序」中安装 LiteRight 后，打开「终端」执行下列诊断命令（默认**只读**，不会修改设置）：

```sh
bash "/Volumes/LiteRight Developer Preview/diagnose-finder-sync.sh" "/Applications/LiteRight.app"
```

若诊断显示扩展未注册，可以由开发者**明确选择**执行（此命令注册并请求启用当前登录用户的 Finder 扩展，但不会关闭任何 macOS 安全保护）：

```sh
bash "/Volumes/LiteRight Developer Preview/diagnose-finder-sync.sh" --enable "/Applications/LiteRight.app"
```

也可以直接在终端执行：

```sh
pluginkit -m -vv -i com.wuhunyu.literight.finder
```

通常以 `+` 开头表示启用，`-` 或 `!` 或完全没有输出均应继续检查。随后前往「系统设置 → 通用 → 登录项与扩展 → Finder 扩展」，确认 LiteRight 已启用；必要时手动重新启动 Finder（Dock 内 Option+右键 Finder → 重新开启）。**不要**认为 `pluginkit` 返回成功就证明菜单真的出现。

安装路径在 `~/Applications` 的用户，请将命令中的 `/Applications/LiteRight.app` 换成实际路径。请先移走旧版本重复副本，否则 LaunchServices/PlugInKit 可能选择旧扩展。安装包采用 ad-hoc 沙盒签名，可以用于本机测试 Finder Sync 注册，但实际五项操作与 App Group 授权仍须按 Issue #3 实机核验。

## 本包可以验证什么？

可以尝试验证 LiteRight 的应用启动、设置界面、菜单栏图标、界面配置等无需真实共享扩展权限的功能。GitHub Actions 的构建和 GUI 测试是自动化证据，但开发者电脑仍需实际观察。

**不能视为已通过的项目：** Finder Sync 是否在系统设置中启用、Finder 右键菜单是否出现、`group.com.wuhunyu.literight` 的跨进程 App Group 读写、通过 Finder 扩展触发的终端和隐藏文件操作。当前 `group.` 前缀 App Group 在新版 macOS 上还可能需要由相同 Apple Developer Team 签名并授权（以及对应 provisioning profile）。用户选择「仍要打开」只处理 Gatekeeper 的应用打开限制，**不会替代这些权限**。

完整 Finder Sync 功能验收仍属于 [Issue #3](https://github.com/wuhunyu/lite-right/issues/3)，需使用正确的开发者签名与 [签名实机测试指南](https://github.com/wuhunyu/lite-right/blob/main/docs/finder-real-machine-acceptance.md)。正式发布状态仍是 **No-Go**。

## 下载与版本规则

- GitHub Actions → **LiteRight macOS unnotarized developer preview**：可下载本次构建的 ZIP、DMG 和校验文件 Artifact（保留 30 天）。
- 以 `preview-v*` 开头的 Git 标签会发布 GitHub **Pre-release**，附带相同文件。
- 只有明确标注 `[publish-preview]` 的 `main` 提交才会自动生成一次按提交 SHA 命名的 Pre-release；普通 main 提交只上传 Actions 构建产物，避免生成大量 Release。
- 无需在 GitHub Actions 中配置 Apple 证书或公证密钥。若以后要进行完整 Finder Sync 验收，必须另建有开发者签名的构建/验收流程。
