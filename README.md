# WorkBuddy Traffic Light

A small Windows always-on-top traffic light for WorkBuddy.

[中文说明](README.zh-CN.md)

## Requirements

- Windows 10 or later
- Windows PowerShell 5.1
- WorkBuddy session files under `%USERPROFILE%\.workbuddy\sessions`

## Release

- 用户可以直接从 GitHub Releases 页面下载最新版本。
- 下载后解压或直接运行内置的 PowerShell 脚本即可使用。
- 如果你只是想快速安装或测试，不需要克隆完整仓库。

## Session Directory

The monitor reads WorkBuddy session files under:

```text
%WORKBUDDY_HOME%\sessions
```

If `WORKBUDDY_HOME` is not set, it falls back to:

```text
%USERPROFILE%\.workbuddy\sessions
```

Current WorkBuddy desktop builds write native `*.json` heartbeat session files there. The monitor also supports Codex-style `*.jsonl` event logs when present.

## Lights

- Yellow: WorkBuddy is working.
- Flashing yellow: WorkBuddy needs approval or user input.
- Green: the observed WorkBuddy runs are complete.
- Red: no readable WorkBuddy session is available or status reading failed.

The monitor is read-only. It does not edit sessions, approve commands, or send data over the network.

## Quick Start

1. Download or clone this repository.
2. Open PowerShell in the project directory.
3. Run the start command:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\start-traffic-light.ps1
```

The traffic light appears near the top-right corner of the desktop. Drag it with the left mouse button to move it. Right-click the light and choose `Exit` to close it.

If the light stays red, make sure WorkBuddy is running and writing session files under `%WORKBUDDY_HOME%\sessions` or `%USERPROFILE%\.workbuddy\sessions`.

## Scripts

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\start-traffic-light.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\stop-traffic-light.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\WorkBuddyTrafficLight.ps1 -Probe
```

Enable or disable launch at sign-in:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\install-startup.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\uninstall-startup.ps1
```

## Test

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\test-status-engine.ps1
```

## License

[MIT](LICENSE)
