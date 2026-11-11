@echo off
setlocal

set SCRIPT_DIR=%~dp0
set PS_SCRIPT=%SCRIPT_DIR%manage-associations.ps1

if not exist "%PS_SCRIPT%" (
    echo Error: manage-associations.ps1 not found in %SCRIPT_DIR%
    pause
    exit /b 1
)

set ACTION=%1
if "%ACTION%"=="" set ACTION=install

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%" -Action %ACTION%

endlocal
