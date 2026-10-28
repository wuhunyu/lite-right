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
