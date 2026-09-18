---
name: dabin-one-click-skin
description: Create, apply, inspect, pause, or restore a local image skin for Codex Desktop on Windows x64. Use when the user asks to change the Codex background or troubleshoot this skin.
---

# 大斌 · Codex 换肤

使用本技能为 Windows x64 的 Codex Desktop 应用本地图片主题。它通过回环 CDP（默认 `127.0.0.1:9341`）在当前页面注入 CSS；不改写 Codex 程序文件、账户、登录态或安全配置。

## 选择操作

- 用户要选图或直观操作时，运行 `scripts/StartDabinSkin.bat`。
- 用户提供了图片绝对路径时，运行 `scripts/dabin-skin.ps1 -Action Apply -ImagePath <绝对路径>`。
- 应用前可运行 `-Action Check`；它会验证 Node.js 22+ 与当前 Codex 主窗口的 CDP 连接。
- 应用后必须运行 `-Action Status`。仅当输出 `mode: active`、`injected: true` 且 `controller: running` 时，才报告主题已生效。
- 用户要求临时移除或恢复原生界面时，运行 `-Action Restore`。不要删除 `runtime/` 中的状态文件代替恢复操作。

## 交互与失败处理

启动器提供图片预览、连接检查、应用和恢复。支持 PNG、JPG/JPEG、BMP、WebP，单张限制 8 MB。启动器状态会按“待连接 → 检测中 → 已连接 → 已应用”变化；只有连接检查成功后才启用“应用到 Codex”。界面使用不透明工作台保障控件可读性，用户消息固定为深底白字。

完整包附带 `assets/dabin-codex-skin-icon.ico`。若用户要创建桌面快捷方式，可将该图标用于 `StartDabinSkin.bat` 的快捷方式；图标用掀开的主题层和右下角 Codex 徽章表达本 Skill 的本地换肤功能，不影响脚本行为。

如果检查或应用失败，先保留错误原文。最常见原因是 Codex 仅在后台、停在登录页，或尚未打开实际主窗口；请用户打开含侧栏和输入框的 Codex 主界面后重试。不要尝试结束进程、修改 Codex 安装目录、重启系统或要求用户重新登录。

图片数据和运行状态仅保存于本技能的 `runtime/` 目录，不能提交到仓库，也不能对外上传。

详细图文说明见 [使用教程](docs/使用教程.md)。
