---
name: traffic-light
description: Start, stop, inspect, or configure the WorkBuddy Traffic Light Windows status overlay. Use when the user asks to launch the WorkBuddy traffic light, close it, check its state, or enable/disable startup.
---

# WorkBuddy Traffic Light

Use the scripts in this plugin's `scripts` directory.

## Actions

- Start: run `start-traffic-light.ps1`.
- Stop: run `stop-traffic-light.ps1`.
- Enable startup: run `install-startup.ps1`.
- Disable startup: run `uninstall-startup.ps1`.
- Inspect current inferred state without opening a window:
  `WorkBuddyTrafficLight.ps1 -Probe`.

Run PowerShell scripts with:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File <script-path>
```

The overlay is read-only. Never change or delete WorkBuddy session files.

## State Meaning

- Yellow steady: one or more WorkBuddy turns are active.
- Yellow flashing: a command approval or user response is pending.
- Green: all observed turns have completed.
- Red: no readable WorkBuddy session was found or the monitor encountered an error.
