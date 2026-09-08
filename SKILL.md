---
name: dabin-one-click-skin
description: Create, apply, check, pause, or restore image themes for Codex Desktop on Windows x64. Use for requests to change Codex skin/wallpaper or troubleshoot a custom theme.
---

# 大斌一键换肤

Use this skill only with Windows x64 Codex Desktop. It applies themes through loopback CDP on `127.0.0.1:9341`; it does not modify Codex binaries, `app.asar`, signatures, credentials, or account settings.

## User-facing entry point

Run `scripts/StartDabinSkin.bat` to open the image picker. It accepts PNG, JPG/JPEG, BMP, and WebP. The launcher normalizes an image, creates a user theme, applies it to the active Codex window, and reports the exact result.

## Agent workflow

1. Run `scripts/dabin-skin.ps1 -Action Check` before applying a theme.
2. For an image request, run `-Action Apply -ImagePath <absolute path>`. The image is downscaled to 1280px wide and stored as JPEG to avoid oversized inline CSS payloads. User messages stay on a dark bubble with white text for reliable contrast.
3. Verify with `-Action Status`. Report visual success only when `mode` is `active`, `failed` is empty, and the renderer CSS includes the returned theme id.
4. Run `-Action Pause` only when the user asks to remove the theme for the current session. Run `-Action Restore` only when the user asks to restore native Codex; it can disable the persistent skin controller.

## Boundaries

- Applying can restart Codex but should not require sign-in.
- Do not enable persistent skin without the user's explicit request.
- If the engine reports a Store/Win32 or process-ownership conflict, stop and show the exact message. Do not kill processes or uninstall Codex.
- Keep source images local. Never package a user's images, logs, profile state, or authentication data.

The embedded engine is a modified HeiGe Codex Skin Studio runtime. See `NOTICE.md` and `LICENSE` for upstream attribution and licensing.
