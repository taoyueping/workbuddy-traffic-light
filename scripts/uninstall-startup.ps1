$shortcutPath = Join-Path ([Environment]::GetFolderPath("Startup")) "WorkBuddy Traffic Light.lnk"
if (Test-Path -LiteralPath $shortcutPath) {
    Remove-Item -LiteralPath $shortcutPath -Force
}
