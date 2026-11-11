@echo off
setlocal

set SCRIPT_DIR=%~dp0
set PS_SCRIPT=%SCRIPT_DIR%manage-associations.ps1

if not exist "%PS_SCRIPT%" (
    echo Error: manage-associations.ps1 not found in %SCRIPT_DIR%
    pause
    exit /b 1
)

set ARG1=%~1

if "%ARG1%"=="" (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%"
) else if /i "%ARG1%"=="install" (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%" -Import
) else if /i "%ARG1%"=="-import" (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%" -Import
) else (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%" -NeovidePath "%ARG1%"
)

endlocal
