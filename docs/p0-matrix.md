# P0 Finder Sync 真机兼容验证记录

状态：**Not verified — No-Go pending macOS 27 physical-machine verification**。

当前自动验证范围：LiteRightCore Swift 单元测试；macOS GitHub Actions Xcode 编译。

以下项目不可仅凭 CI 代替：

| Finder 场景 | 空白处菜单 / 层级 | 选中单项 / 多项 | URL/路径 | 操作 | 状态 |
| --- | --- | --- | --- | --- | --- |
| $HOME 本地文件夹 | 10 次 | 10 次 | 10 次 | 10 次 | 待测 |
| 桌面 | 10 次 | 10 次 | 10 次 | 10 次 | 待测 |
| 文稿/下载 | 10 次 | 10 次 | 10 次 | 10 次 | 待测 |
| iCloud Drive | 10 次 | 10 次 | 10 次 | 10 次 | 待测 |
| 外接 APFS / exFAT | 10 次 | 10 次 | 10 次 | 10 次 | 待测 |
| 网络共享 | 10 次 | 10 次 | 10 次 | 10 次 | 待测 |
| 最近使用 / 搜索结果 | 10 次 | 10 次 | 10 次 | 10 次 | 待测 |

桥接：从 Finder Extension 唤起未运行宿主，重复 20 次；成功率、App Group 和自动化授权来源仍待测。
终端：Terminal / iTerm2 新 Window、Tab 偏好、路径特殊字符各 20 次待测。

未记录真机数据前，不得将本 PoC 标记为 Go，也不得打包正式发布。

## CI 自动化覆盖

参见 [ci-runtime-tests.md](ci-runtime-tests.md)。Swift/Core 与实际 macOS 构建产物可在 GitHub Actions 校验；Finder 右键可见性与权限仍为人工 P0，CI 的 pluginkit 注册试验不等同于通过。

## 实测补充（2026-10-28）

GitHub Actions `xcode-27` 已通过 27 项真实文件系统/Swift 单测和完整应用包/扩展编译，未完成 Finder 实际右键菜单验收。
GUI 试验 2 项测试均失败，详情 [Issue #4](https://github.com/wuhunyu/lite-right/issues/4)；签名实机验收详见 [Issue #3](https://github.com/wuhunyu/lite-right/issues/3)。

## 实测补充（2026-10-29）

[CI #40806618329](https://github.com/wuhunyu/lite-right/actions/runs/40806618329) 已验证修复后的 macOS 27 应用可以在 AppKit 状态栏显示时启动：Required 通过，XCUITest 5/5 全部通过。此前 [Issue #4](https://github.com/wuhunyu/lite-right/issues/4) 的启动崩溃已在 CI 中不再复现。

**这不改变本表的 No-Go 状态**：签名 Finder Sync 真实右键菜单覆盖范围、自动化授权与外部磁盘等场景，仍需按 [Issue #3](https://github.com/wuhunyu/lite-right/issues/3) 实机验证。

## Issue #3 开发增量（2026-10-29）

- 已加入 Finder 监控目录的原生 UI：选择目录、移除、刷新，允许用户添加 `/Volumes/...` 或网络挂载目录；配置的离线卷路径会保留，实际注册时只使用存在的目录。
- Host 使用 `DistributedNotificationCenter` 通知 Finder Sync 重新读取 App Group 监控目录；通知与 Finder 实际呈现仍须在签名实机复核。
- 新增纯 Swift 右键上下文解析测试：空白处、文件、文件夹、多选、侧边栏、搜索结果、不可用路径；非当前监控目录的 Finder 菜单并不因此自动可用。
- `ci/verify-signed-app.swift` 可在已签名安装包上检查 App/appex 签名、同一 Developer Team 和 App Group；未签名的 Actions 构建**只能验证其应被拒绝**，不能证明签名安装已达标。
- Finder 扩展启用状态与共享容器状态可由 App 设置页显示；它们只是系统 API 观测结果，不能证明右键操作完成。

### 必须填写的签名实机证据

| 字段 | 实测值 / 证据 |
| --- | --- |
| 测试日期 / 操作人 | 待测 |
| macOS 系统版本与 build | 待测 |
| Mac 硬件型号与芯片 | 待测 |
| 测试代码提交 SHA | 待测 |
| Apple Developer TeamIdentifier | 待测 |
| 主 App + Finder appex 签名检查结果 | 待测 |
| App Group 同名与实际共享读写 | 待测 |
| Finder 扩展在系统设置中已启用（截图） | 待测 |
| Finder 右键菜单实际层级及 5 项操作截图 | 待测 |
| 桌面、文稿、下载、iCloud、外置卷、网络共享覆盖 | 待测 |
| 终端新 Window 与 TCC 拒绝测试 | 待测 |
| 菜单排序/显隐、菜单栏/Dock、登录项重启持久化 | 待测 |
| 最终结论（Go / No-Go） | **No-Go，尚无签名实机证据** |

详细步骤和命令：[finder-real-machine-acceptance.md](finder-real-machine-acceptance.md)。不得凭 `pluginkit` 注册成功、`isExtensionEnabled` 读数或 CI 全绿，把上述字段改为“通过”。
