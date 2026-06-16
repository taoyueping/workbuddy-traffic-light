$processes = Get-CimInstance Win32_Process -Filter "Name = 'powershell.exe'" -ErrorAction SilentlyContinue |
    Where-Object { $_.CommandLine -like "*WorkBuddyTrafficLight.ps1*" }

foreach ($process in $processes) {
    Stop-Process -Id $process.ProcessId -Force
}
