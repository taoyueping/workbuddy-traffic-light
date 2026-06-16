# WorkBuddy 红绿灯

一个用于 WorkBuddy 的 Windows 桌面状态灯。它会显示在桌面右上角并保持置顶，让你不用反复切回 WorkBuddy 窗口，也能看到任务正在运行、等待批准，还是已经完成。

[English](README.md)

## 状态说明

- 黄灯常亮：WorkBuddy 正在工作。
- 黄灯闪烁：WorkBuddy 正在等待命令批准或用户输入。
- 绿灯：当前观察到的 WorkBuddy 任务均已完成。
- 红灯：没有检测到可读取的 WorkBuddy 会话，或状态读取失败。

## 简单使用

1. 下载或克隆本仓库。
2. 在项目目录中打开 PowerShell。
3. 运行启动命令：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\start-traffic-light.ps1
```

红绿灯会显示在桌面右上角附近。按住鼠标左键可以拖动位置；右键点击红绿灯，选择 `Exit` 即可退出。

如果红灯一直亮，请确认 WorkBuddy 正在运行，并且正在写入 `%WORKBUDDY_HOME%` 或 `%USERPROFILE%\.workbuddy` 下的本地状态文件。

## 运行要求

- Windows 10 或更高版本
- Windows PowerShell 5.1
- WorkBuddy 本地状态文件位于 `%USERPROFILE%\.workbuddy`

## 状态来源

程序只读 WorkBuddy 的本地状态文件：

- `%USERPROFILE%\.workbuddy\projects\**\*.jsonl`：主要来源，用来判断任务是否正在运行。
- `%USERPROFILE%\.workbuddy\sessions\*.json`：WorkBuddy 桌面端心跳/会话检测。
- `%USERPROFILE%\.workbuddy\logs\**\*.log`：备用来源，用来补充 prompt 和模型流事件。

可以通过环境变量覆盖 WorkBuddy 主目录：

```text
%WORKBUDDY_HOME%
```

如果没有设置 `WORKBUDDY_HOME`，则读取：

```text
%USERPROFILE%\.workbuddy
```

程序会优先根据项目事件流判断状态：当出现 reasoning、工具调用或网页获取等 `function_call` 事件时保持黄灯；当项目事件流写入 assistant 回复后回到绿灯。

## 启动和关闭

启动红绿灯：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\start-traffic-light.ps1
```

关闭红绿灯：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\stop-traffic-light.ps1
```

查看当前状态但不打开窗口：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\WorkBuddyTrafficLight.ps1 -Probe
```

## 开机自启

启用登录后自动启动：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\install-startup.ps1
```

取消自动启动：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\uninstall-startup.ps1
```

## 运行测试

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\test-status-engine.ps1
```

测试成功时会输出：

```text
Status engine tests passed.
```

## 隐私说明

程序只读取 WorkBuddy 会话日志，不会修改或删除会话，不会自动批准命令，也不会向网络发送数据。

## 许可证

本项目使用 [MIT License](LICENSE)。
