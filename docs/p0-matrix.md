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
