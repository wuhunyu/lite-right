# LiteRight / Issue #3 — macOS 27 签名 Finder Sync 实机验收

> 当前状态：**No-Go**。本文帮助搭建和记录可重复的签名实机测试；已通过的 GitHub Actions 不代表 Finder 菜单可用。

## 1. 测试前置条件

- 一台登录**图形桌面会话**的 macOS 27 Mac（记录 `sw_vers`、机型、芯片）。
- Xcode 27 SDK、XcodeGen、Swift 6；Xcode 中登录有权签名 App Group 的 Apple Developer Team。
- 开发团队已配置 `group.com.wuhunyu.literight` App Group，签名配置同时覆盖主 App `com.wuhunyu.literight` 和 Finder 扩展 `com.wuhunyu.literight.finder`。
- 本机只保留一份用于测试的 LiteRight.app，避免 Finder 注册到相同 Bundle ID 的旧版本；提前记录版本和 git SHA。
- 无需关闭 SIP、提权注入 Finder、强行改写 TCC 数据库，也不要将开发证书上传到公开仓库。

### 签名构建

在**已安装并配置 Apple Developer Team 的本地 macOS 27** 执行：

```sh
brew install xcodegen
python3 -m venv .icon-venv
.icon-venv/bin/python -m pip install pillow cairosvg
.icon-venv/bin/python tools/export-icons.py
xcodegen generate

export DEVELOPMENT_TEAM="填写你自己 Apple Developer Team ID"
xcodebuild -project LiteRight.xcodeproj -scheme LiteRight \
  -configuration Release -destination 'platform=macOS' \
  -derivedDataPath "$PWD/.signed-derived" \
  -allowProvisioningUpdates DEVELOPMENT_TEAM="$DEVELOPMENT_TEAM" \
  CODE_SIGNING_ALLOWED=YES build

APP="$PWD/.signed-derived/Build/Products/Release/LiteRight.app"
swift ci/verify-signed-app.swift "$APP"
sw_vers
uname -m
git rev-parse HEAD
```

若签名构建失败，先在 Xcode 的 Signing & Capabilities 中配置同一 Team 和 App Group；不要通过 `CODE_SIGNING_ALLOWED=NO` 绕过本验收。签名检查报告应包含两份有效签名、相同 TeamIdentifier 和相同 `group.com.wuhunyu.literight` 权限。检查失败时停止，不进入菜单功能验收。

### 安装、启用与诊断

将验证通过的应用复制到一个明确的安装位置（例如 `~/Applications/LiteRight.app`），确保没有其他相同 Bundle ID 的旧副本；复制后重新执行签名检查，再启动：

```sh
open "$HOME/Applications/LiteRight.app"
swift ci/verify-signed-app.swift "$HOME/Applications/LiteRight.app"
/usr/bin/pluginkit -m -i com.wuhunyu.literight.finder
```

在 LiteRight「权限管理」页面观察系统报告的 Finder 扩展启用状态和 App Group 主应用可访问状态；使用「打开扩展设置」进入系统设置，按系统提示启用该扩展并记录截图。`pluginkit` 列表仅作诊断，**不等于扩展已启用，也不等于菜单能出现**。

在「通用 → Finder 监控」中添加测试目录。默认监控用户主目录；外接卷、网络共享等目录需要**明确添加**，然后点击「刷新监控目录」。目录卸载期间会保留配置，但不会注册一个不存在的路径，重新挂载后再次点击刷新。

## 2. 测试数据与菜单验证

建议准备 `~/LiteRightAcceptance` 文件夹，包含：

- 空白文件夹、普通 TXT/Markdown、具有中文与空格的目录；
- 名称含单引号、双引号、美元符号、Tab 或换行的目录（在终端操作前确认不会误定位）；
- 两个不同目录内的文件、一个普通文件夹和一个 `.app` 包。

对下列情况按 [P0 验收矩阵](p0-matrix.md) 指定次数重复验证，记录实际菜单层级、可见项、是否灰显、实际目标路径及截图：

| 场景 | 预期的路径解析 | 预期限制 |
| --- | --- | --- |
| Finder 目录空白处右键 | 当前目录 | 必须属于监控范围 |
| 单选普通文件 | 文件父目录 | 新建不应落在文件自身 |
| 单选文件夹 | 被选中文件夹 | 默认创建在文件夹内 |
| 多选同目录普通文件 | 共同父目录 | 各操作目标一致 |
| 多选不同目录文件 / 文件夹 | 无确定唯一目录 | 路径操作禁用 |
| 侧边栏选中文件夹 | 文件夹本身 | 受 Finder 系统允许的上下文制约 |
| 搜索结果中选中真实文件 | 真实父目录 | 搜索结果空白处不应猜测路径 |
| 外接卷 / 网络共享 | 显式登记目录下的真实位置 | 卸载、只读、访问拒绝必须明确失败 |
| iCloud Drive | 已同步且可访问的真实路径 | 不得声称覆盖所有云端占位文件 |

Finder Sync 返回的菜单结构和系统将其放在一级还是子菜单，最终由 Finder 控制。**若系统把五项放入二级菜单，应记录为不满足首版“平铺一级菜单”的产品验收要求，不能把它写成通过，也不要靠私有 Finder 注入绕过。**

## 3. 操作与权限验证

1. 在空白处、文件、文件夹分别执行「新建 TXT」「新建 Markdown」；确认文件名冲突安全递增、不覆盖原文件，权限拒绝/只读卷有明确反馈。
2. 执行「复制目录路径」；确认粘贴板与目标目录一致，Unicode、空格、符号链接及包目录行为符合规则。
3. 在终端设置中分别选择可用的 Terminal.app 与 iTerm2；每次右键操作后确认**新窗口**而非 Tab，检查目录名引号、美元符号、换行、拒绝 Apple Events 自动化授权时的提示。
4. 切换「显示隐藏文件」，核实其影响整个 Finder 而不是只影响当前文件夹，需用户确认后才触发 Finder 重启。
5. 修改五项菜单排序、显隐、所选终端、Shell、菜单栏及 Dock 图标和登录启动；退出主应用、重新登录并重启后检查持久化。确认 Finder 扩展重新载入共享设置。
6. 在 Finder 扩展被关闭、测试目录卸载及主 App 未运行时，观察失败提示和是否会重复创建文件。
7. 对于系统不支持的 Finder 场景，标记「不支持／受系统限制」，不要以未测试代替失败率。

## 4. 必须保留的证据

```sh
sw_vers
system_profiler SPHardwareDataType | head -n 24
git rev-parse HEAD
swift ci/verify-signed-app.swift "$HOME/Applications/LiteRight.app"
/usr/bin/pluginkit -m -i com.wuhunyu.literight.finder
```

附带：系统设置 Finder 扩展已启用截图、目录监控设置截图、各场景真实右键菜单截图、单项操作结果、终端新窗口截图、用户授权/拒绝场景（请删去私人路径和用户名）。验收矩阵逐场景填写实际通过次数、失败次数及可复现步骤。

只有**签名、App Group、系统启用、实际 Finder 菜单及五项操作**全部满足验收标准，且无 P0 不兼容，才能考虑标记 Issue #3 完成。发行、公证和性能另行验收。

官方文档： https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/Finder.html
