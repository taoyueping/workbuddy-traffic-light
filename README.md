# WorkBuddy Traffic Light

A small Windows always-on-top traffic light for WorkBuddy.

[中文说明](README.zh-CN.md)

## Requirements

- Windows 10 or later
- Windows PowerShell 5.1
- WorkBuddy local status files under `%USERPROFILE%\.workbuddy`

## Release

- Download the latest packaged build from GitHub Releases.
- If you run from source, clone the repository and use the scripts below.
- After status-detection changes, packaged users should install the latest release.

## Status Sources

The monitor reads WorkBuddy's local, read-only status files:

- `%USERPROFILE%\.workbuddy\projects\**\*.jsonl`: primary source for live task activity.
- `%USERPROFILE%\.workbuddy\sessions\*.json`: WorkBuddy desktop heartbeat/session detection.
- `%USERPROFILE%\.workbuddy\logs\**\*.log`: fallback source for prompt and stream events.

You can override the WorkBuddy home directory with:

```text
%WORKBUDDY_HOME%
```

If `WORKBUDDY_HOME` is not set, it falls back to:

```text
%USERPROFILE%\.workbuddy
```

The monitor keeps the light yellow while project events show active reasoning or tool calls, including `function_call` events such as web page fetching. It returns to green after the project event stream records an assistant response.

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

If the light stays red, make sure WorkBuddy is running and writing files under `%WORKBUDDY_HOME%` or `%USERPROFILE%\.workbuddy`.

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
