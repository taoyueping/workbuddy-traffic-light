$startupDirectory = [Environment]::GetFolderPath("Startup")
$shortcutPath = Join-Path $startupDirectory "WorkBuddy Traffic Light.lnk"
$startScript = Join-Path $PSScriptRoot "start-traffic-light.ps1"

$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = "powershell.exe"
$shortcut.Arguments = "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$startScript`""
$shortcut.WorkingDirectory = $PSScriptRoot
$shortcut.Description = "Start the WorkBuddy Traffic Light status overlay"
$shortcut.Save()

Write-Output $shortcutPath
