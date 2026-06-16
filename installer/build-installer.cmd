@echo off
setlocal

set "SCRIPT=%~dp0workbuddy-traffic-light.iss"
set "ISCC=%ProgramFiles(x86)%\Inno Setup 6\ISCC.exe"

if not exist "%ISCC%" set "ISCC=%ProgramFiles%\Inno Setup 6\ISCC.exe"

if not exist "%ISCC%" (
    for /f "delims=" %%I in ('where ISCC.exe 2^>nul') do (
        set "ISCC=%%I"
        goto :found
    )
)

:found
if not exist "%ISCC%" (
    echo.
    echo [错误] 没有找到 Inno Setup 6。
    echo 请先安装 Inno Setup，再重新运行本文件。
    echo.
    pause
    exit /b 1
)

echo 正在生成安装包...
"%ISCC%" "%SCRIPT%"

if errorlevel 1 (
    echo.
    echo [失败] 安装包编译失败，请查看上面的错误信息。
    pause
    exit /b 1
)

echo.
echo [完成] 安装包已生成到项目根目录的 dist 文件夹。
pause
