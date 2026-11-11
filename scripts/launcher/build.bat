@echo off
rem Usage: build.bat [compiler]
rem   compiler: gcc (default), clang, tcc, or cl
rem
rem The selected compiler must be available on PATH.
rem For cl, run this from a Developer Command Prompt.

setlocal
cd /d "%~dp0"

set "CC=%~1"
if not defined CC set "CC=gcc"

if /i "%CC%"=="cl" goto :msvc
if /i "%CC%"=="msvc" goto :msvc

rem Build the icon resource when windres is available.
if not exist launcher.res windres launcher.rc -O coff -o launcher.res

if exist launcher.res (
    %CC% -mwindows -O2 launcher.c launcher.res -o neovide-launcher.exe -luser32 -lshell32
) else (
    %CC% -mwindows -O2 launcher.c -o neovide-launcher.exe -luser32 -lshell32
)
if errorlevel 1 exit /b 1
goto :done

:msvc
rc /nologo launcher.rc
if errorlevel 1 exit /b 1
cl /nologo /O2 /W3 /DUNICODE /D_UNICODE launcher.c launcher.res /Fe:neovide-launcher.exe /link /SUBSYSTEM:WINDOWS user32.lib shell32.lib
if errorlevel 1 exit /b 1
del /q launcher.obj >nul 2>&1

:done
echo Build successful: %~dp0neovide-launcher.exe
exit /b 0
