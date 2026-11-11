@echo off
setlocal

:: Default server pipe for single-instance Neovide
set "PIPE=\\.\pipe\neovide-server"

:: Get full path to target (file or directory)
set "TARGET=%~f1"

:: Check if Neovim server named pipe is active
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "if ([System.IO.File]::Exists('%PIPE%')) { exit 0 } else { exit 1 }"
if %ERRORLEVEL% equ 0 goto reuse

:spawn
:: No active instance: spawn Neovide listening on the shared pipe
if "%TARGET%"=="" (
    start "" neovide -- --listen "%PIPE%"
) else if exist "%TARGET%\*" (
    start "" neovide --chdir "%TARGET%" -- --listen "%PIPE%" "%TARGET%"
) else (
    start "" neovide -- --listen "%PIPE%" "%TARGET%"
)
exit /b 0

:reuse
:: Instance exists: route file/directory to running Neovide instance
if "%TARGET%"=="" (
    :: Bring window forward
    nvim --headless --server "%PIPE%" --remote-send "<Esc>" >nul 2>&1
) else if exist "%TARGET%\*" (
    :: Target is a directory: change directory and open Neo-tree
    nvim --headless --server "%PIPE%" --remote-send "<Esc>:cd %TARGET%<CR>:Neotree dir=%TARGET%<CR>" >nul 2>&1
) else (
    :: Target is a file: open in active window
    nvim --headless --server "%PIPE%" --remote-tab "%TARGET%" >nul 2>&1
)
exit /b 0
