# WorkBuddy Traffic Light

A small Windows always-on-top traffic light for WorkBuddy.

![WorkBuddy Traffic Light preview](assets/workbuddy-traffic-light-preview.png)

[中文说明](README.zh-CN.md)

## Requirements

- Windows 10 or later
- Windows PowerShell 5.1
- WorkBuddy session logs in JSONL format

## Session Directory

The monitor reads JSONL files under:

```text
%WORKBUDDY_HOME%\sessions
```

If `WORKBUDDY_HOME` is not set, it falls back to:

```text
%USERPROFILE%\.workbuddy\sessions
```

## Lights

- Yellow: WorkBuddy is working.
- Flashing yellow: WorkBuddy needs approval or user input.
- Green: the observed WorkBuddy runs are complete.
- Red: no readable WorkBuddy session is available or status reading failed.

The monitor is read-only. It does not edit sessions, approve commands, or send data over the network.

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
