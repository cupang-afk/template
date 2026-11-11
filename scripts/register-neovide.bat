@echo off
setlocal

set SCRIPT_DIR=%~dp0
set PS_SCRIPT=%SCRIPT_DIR%manage-associations.ps1

if not exist "%PS_SCRIPT%" (
    echo Error: manage-associations.ps1 not found in %SCRIPT_DIR%
    pause
    exit /b 1
)

set NEOVIDE_PATH=%~1

if "%NEOVIDE_PATH%"=="" (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%"
) else (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%" -NeovidePath "%NEOVIDE_PATH%"
)

endlocal
