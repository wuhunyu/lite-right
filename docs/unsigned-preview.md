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

## 开发者测试包的右键执行通道（仅本地诊断用途）

此前的 ad-hoc 安装包可能在 `RequestStore.save()` 写入 App Group 时直接失败：Finder Sync 的错误只写进系统日志/播放提示音，导致右键菜单看得见但点了没有反应。这与 Finder 菜单是否显示是两个独立问题。

**新版测试构建** 在编译时启用 `LITERIGHT_UNTRUSTED_PREVIEW`，右键点击将通过本地自定义 URL Scheme 唤醒 LiteRight 主进程，不再把执行请求写入未经授权的 App Group。正式 Developer Team 签名构建不启用该标记，仍使用原来的 App Group UUID 请求桥接。请勿将开发者测试版视为生产安全配置。

此通道采用如下限制：

- 自定义 URL 可以由其他应用发起，**来源不可认证**，因此只允许五个固定动作；无法注入任意 shell 脚本、命令或外部可执行路径。
- 请求包含随机 ID、60 秒有效期；大小及目录路径长度有限制，拒绝相对路径、根目录、路径穿越、重复/附加参数。
- 主应用从自身独立保存的设置重新读取监控目录、校验真实目录、解析符号链接并确认其属于监控范围；不会直接信任 URL 携带的目标位置。
- 限制单进程每分钟 30 次请求；重复的请求 ID 在同一进程中不重复执行。文件创建采用原子的无覆盖写入。隐藏文件显示通过需用户授权的本机键盘事件切换，不发送任意脚本。
- 不从外部 URL 执行任意命令；打开终端使用主应用中用户所选的 Terminal/iTerm2 与 Shell，并安全引用目标路径。

**注意**：以上仍不足以抵御有能力反复发起自定义 URL 的本地恶意程序。因此本方案只为开发者 ad-hoc 安装包恢复真实功能测试；正式发布仍应使用已授权的 App Group/XPC，不得将受限预览通道默认引入正式签名构建。

可以按顺序右键测试「新建 Markdown」（确认出现文件）、「复制目录路径」（确认剪贴板）、「在终端中打开」（确认新的终端窗口）以及「切换隐藏文件显示」（确认 Finder 窗口立即显示/隐藏文件且不重启）。若依然无反应，可执行：

```sh
log show --last 3m --style compact --info --predicate 'subsystem == "com.wuhunyu.literight.finder" OR subsystem == "com.wuhunyu.literight"'
```

重点观察 `finder_action_selected`、`finder_action_transport`、`preview_request_received`、`preview_request_completed`、`operation_failed`。**系统日志与编译通过不等于真实右键功能验收通过。**

## 设置无法保存的已知问题与修复范围

2026-10-29 实机确认：此前的 ad-hoc 测试版尝试向 `group.com.wuhunyu.literight` 保存菜单设置时，macOS `cfprefsd` 记录 `rejecting write ... requires user-preference-write or file-write-data sandbox access`。原代码忽略 `UserDefaults.synchronize()` 返回的失败，因此“勾选变化后重启恢复默认”。

新的主应用将所有用户设置**独立保存**至 `~/Library/Application Support/LiteRight/preferences.json`（原子写入、失败显示错误），再尝试同步到 App Group。如果 macOS 仍拒绝 App Group 写入，会显示“本机设置已保存，但 Finder 扩展共享配置同步失败”，而不是丢失本机设置。可在更改菜单勾选后运行 `ls -l "$HOME/Library/Application Support/LiteRight/preferences.json"`，随后退出并重新打开程序验证持续保存。

**此修复只解决主应用本机设置持久化，不等于 Finder Sync 在 ad-hoc 构建中已获得 App Group 读写许可。** 真正的 Finder 右键菜单和操作请求仍需单独签名/跨进程验收，详见 [Issue #3](https://github.com/wuhunyu/lite-right/issues/3)。

## 本包可以验证什么？

可以尝试验证 LiteRight 的应用启动、设置界面、菜单栏图标、界面配置等无需真实共享扩展权限的功能。GitHub Actions 的构建和 GUI 测试是自动化证据，但开发者电脑仍需实际观察。

**不能视为已通过的项目：** Finder Sync 是否在系统设置中启用、Finder 右键菜单是否出现、`group.com.wuhunyu.literight` 的跨进程 App Group 读写、通过 Finder 扩展触发的终端和隐藏文件操作。当前 `group.` 前缀 App Group 在新版 macOS 上还可能需要由相同 Apple Developer Team 签名并授权（以及对应 provisioning profile）。用户选择「仍要打开」只处理 Gatekeeper 的应用打开限制，**不会替代这些权限**。

完整 Finder Sync 功能验收仍属于 [Issue #3](https://github.com/wuhunyu/lite-right/issues/3)，需使用正确的开发者签名与 [签名实机测试指南](https://github.com/wuhunyu/lite-right/blob/main/docs/finder-real-machine-acceptance.md)。正式发布状态仍是 **No-Go**。

## 2026-10-30 菜单设置实时同步（PR #20，待实机验收）

主应用的菜单顺序、勾选显隐和首选终端始终持久化到本机 `HostPreferencesStore`。由于 ad-hoc 预览包的 App Group suite 可能遭 cfprefsd 拒绝写入，预览包另以 `DistributedNotificationCenter` 发送**只含配置**的有大小上限的快照：设置变更时主动广播，Finder 扩展初始化时主动请求；扩展收到后更新内存配置和 Finder 监控目录。此通道不携带操作命令、不启用任意 shell 操作；正式开发者签名构建仍依靠 App Group。

**限制：**通知是进程间易失通信，macOS 沙盒是否允许实际递送必须在用户的 Finder 扩展与主 App 会话中验证。扩展在未收到快照时仍可能使用默认偏好；应记录 `preview_settings_received` 和 `menu_callback visible_count`。不要将 CI 编译或本机 JSON 保存成功误认为菜单已经同步。

隐藏文件操作现在由 LiteRight 主应用使用 Quartz/CoreGraphics 发出物理 Command-Shift-Period（按下/释放 Command、Shift、句点）的键盘事件。发送前确认 Finder 前台与 PostEvent（辅助功能）权限；无需额外 System Events/AppleScript 自动化权限，也不会主动重启 Finder。第一次使用可能出现系统权限授权提示，授权完成后应重新点击菜单。发送后会尝试核对 Finder 的 AppleShowAllFiles 状态，若未检测到改变会明确报错，而不是只记录脚本退出成功。菜单读取 Finder 当前偏好以生成“显示隐藏文件”或“隐藏隐藏文件”，若不可读则显示中性“切换隐藏文件显示”，不会凭空猜测。手动快捷键切换的反映情况同样需要实机验证。

### 验证快捷键是否真正送到 Finder

在已监控的目录中创建隐藏文件（名字以句点开头）：

```sh
mkdir -p "$HOME/LiteRightLocalTest"
touch "$HOME/LiteRightLocalTest/.literight-hidden-check"
open "$HOME/LiteRightLocalTest"
```

先**手动**按一次 ⌘⇧.，确认此 Finder 窗口能显示/隐藏该文件；然后用 LiteRight 右键菜单执行相同切换。该流程**不需要**重启 Finder。测试时记录 Finder 的 PID 前后是否一致，并观察隐藏文件是否立即变化。若快捷键所需的辅助功能授权被拒绝，打开 LiteRight「权限管理 → 辅助功能」，授权后重新测试。不要使用 killall Finder 来掩盖失败。

在 LiteRight 的系统日志中核对 `hidden_toggle_posting`、`hidden_toggle_verified`、`hidden_toggle_denied`、`hidden_toggle_unverified`。CI 能检查按键序列和构建，但不能自动批准真实桌面 TCC，故不能替代用户实机验收。

### 实机核查顺序

1. 保持主应用运行、Finder 扩展已启用，打开监控目录；
2. 隐藏一个菜单项并拖动排序，关闭右键菜单再重新打开，检查是否立刻变化；
3. 把终端改成 iTerm2，下一次打开菜单确认标题、点击确认启动的真实终端；
4. 右键切换隐藏文件，确认 Finder 不退出；然后手动按 ⌘⇧. 并再次右键检查标题和图标；
5. 退出/重启 LiteRight、重新启动 Finder 后重复以上操作；
6. 使用 `log show --last 5m --style compact --info --predicate 'subsystem == "com.wuhunyu.literight.finder" OR subsystem == "com.wuhunyu.literight"'` 收集日志。

真实操作及截图提交到 Issue #3，PR #20 的 CI 通过前不得合并。

## 下载与版本规则

- GitHub Actions → **LiteRight macOS unnotarized developer preview**：可下载本次构建的 ZIP、DMG 和校验文件 Artifact（保留 30 天）。
- 以 `preview-v*` 开头的 Git 标签会发布 GitHub **Pre-release**，附带相同文件。
- 只有明确标注 `[publish-preview]` 的 `main` 提交才会自动生成一次按提交 SHA 命名的 Pre-release；普通 main 提交只上传 Actions 构建产物，避免生成大量 Release。
- 无需在 GitHub Actions 中配置 Apple 证书或公证密钥。若以后要进行完整 Finder Sync 验收，必须另建有开发者签名的构建/验收流程。
