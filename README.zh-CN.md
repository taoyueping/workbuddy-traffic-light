# WorkBuddy 红绿灯

一个用于 WorkBuddy 的 Windows 桌面状态灯。它会显示在桌面右上角并保持置顶，让你不用反复切回 WorkBuddy 窗口，也能看到任务正在运行、等待批准，还是已经完成。

![WorkBuddy 红绿灯预览](assets/workbuddy-traffic-light-preview.png)

[English](README.md)

## 状态说明

- 黄灯常亮：WorkBuddy 正在工作。
- 黄灯闪烁：WorkBuddy 正在等待命令批准或用户输入。
- 绿灯：当前观察到的 WorkBuddy 任务均已完成。
- 红灯：没有检测到可读取的 WorkBuddy 会话，或状态读取失败。

## 运行要求

- Windows 10 或更高版本
- Windows PowerShell 5.1
- WorkBuddy 会话日志为 JSONL 格式

## 会话目录

程序默认读取：

```text
%WORKBUDDY_HOME%\sessions
```

如果没有设置 `WORKBUDDY_HOME`，则读取：

```text
%USERPROFILE%\.workbuddy\sessions
```

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
