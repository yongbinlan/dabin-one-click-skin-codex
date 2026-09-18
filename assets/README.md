# 默认启动背景

`default-launcher-background.png` 为原始参考图；`default-launcher-background-960x720.png` 是按启动器固定画布裁切和缩放的清晰默认背景。启动器只读取此适配版来绘制主视觉，不会把它写入 Codex，也不会上传。

该图由当前用户提供用于本地启动器界面。代码的 MIT 许可不自动授予这张图片的再分发权；在公开发布、推送 GitHub 或更换默认图片前，应确认相应的素材授权。

## 启动器图标

`dabin-codex-skin-icon.ico` 是本项目的 Windows 多尺寸桌面图标；`dabin-codex-skin-icon.png` 为已选定的高清原图。它以悬浮的半透明皮肤、被掀开的动态主题层和右下角 Codex 徽章表现换肤。PNG 由本项目内置的图像生成工具制作，`tools/create_launcher_icon.py` 只负责将其封装成 Windows `.ico`。

前两版图标以 `dabin-codex-skin-icon-v1.*` 和 `dabin-codex-skin-icon-v2.*` 保留在本地，供需要时回退；它们不随发布包分发。
