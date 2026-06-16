#define MyAppName "WorkBuddy Traffic Light"
#define MyAppVersion "1.1.0"
#define MyAppPublisher "taoyueping"
#define MyAppURL "https://github.com/taoyueping/workbuddy-traffic-light"

[Setup]
AppId={{E24008E8-D3DE-469C-9CBC-B7F0E202F1A9}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}/issues
AppUpdatesURL={#MyAppURL}/releases
DefaultDirName={localappdata}\Programs\WorkBuddy Traffic Light
DefaultGroupName=WorkBuddy Traffic Light
DisableDirPage=yes
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
MinVersion=10.0
OutputDir=..\dist
OutputBaseFilename=WorkBuddy-Traffic-Light-Setup-v{#MyAppVersion}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
UninstallDisplayName={#MyAppName}
LicenseFile=..\LICENSE
SetupLogging=yes

[Languages]
Name: "chinesesimp"; MessagesFile: "compiler:Languages\ChineseSimplified.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "startup"; Description: "登录 Windows 后自动启动"; GroupDescription: "附加选项："; Flags: checkedonce
Name: "desktopicon"; Description: "创建桌面快捷方式"; GroupDescription: "附加选项："; Flags: unchecked

[Files]
Source: "..\scripts\*"; DestDir: "{app}\scripts"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "..\assets\*"; DestDir: "{app}\assets"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "..\README.md"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\README.zh-CN.md"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\LICENSE"; DestDir: "{app}"; Flags: ignoreversion

[InstallDelete]
Type: files; Name: "{userstartup}\WorkBuddy Traffic Light.lnk"

[Icons]
Name: "{group}\启动 WorkBuddy 红绿灯"; \
    Filename: "{sys}\WindowsPowerShell\v1.0\powershell.exe"; \
    Parameters: "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File ""{app}\scripts\start-traffic-light.ps1"""; \
    WorkingDir: "{app}\scripts"

Name: "{group}\关闭 WorkBuddy 红绿灯"; \
    Filename: "{sys}\WindowsPowerShell\v1.0\powershell.exe"; \
    Parameters: "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File ""{app}\scripts\stop-traffic-light.ps1"""; \
    WorkingDir: "{app}\scripts"

Name: "{group}\卸载 WorkBuddy 红绿灯"; Filename: "{uninstallexe}"

Name: "{autodesktop}\WorkBuddy 红绿灯"; \
    Filename: "{sys}\WindowsPowerShell\v1.0\powershell.exe"; \
    Parameters: "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File ""{app}\scripts\start-traffic-light.ps1"""; \
    WorkingDir: "{app}\scripts"; Tasks: desktopicon

Name: "{userstartup}\WorkBuddy Traffic Light"; \
    Filename: "{sys}\WindowsPowerShell\v1.0\powershell.exe"; \
    Parameters: "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File ""{app}\scripts\start-traffic-light.ps1"""; \
    WorkingDir: "{app}\scripts"; Tasks: startup

[Run]
Filename: "{sys}\WindowsPowerShell\v1.0\powershell.exe"; \
    Parameters: "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File ""{app}\scripts\stop-traffic-light.ps1"""; \
    WorkingDir: "{app}\scripts"; Flags: runhidden waituntilterminated

Filename: "{sys}\WindowsPowerShell\v1.0\powershell.exe"; \
    Parameters: "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File ""{app}\scripts\start-traffic-light.ps1"""; \
    WorkingDir: "{app}\scripts"; Description: "安装完成后启动 WorkBuddy 红绿灯"; \
    Flags: postinstall nowait skipifsilent

[UninstallRun]
Filename: "{sys}\WindowsPowerShell\v1.0\powershell.exe"; \
    Parameters: "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File ""{app}\scripts\stop-traffic-light.ps1"""; \
    WorkingDir: "{app}\scripts"; RunOnceId: "StopWorkBuddyTrafficLight"; \
    Flags: runhidden waituntilterminated skipifdoesntexist

[UninstallDelete]
Type: files; Name: "{userstartup}\WorkBuddy Traffic Light.lnk"
