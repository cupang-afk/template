@echo off
setlocal

set "SCRIPT_DIR=%~dp0"
cd /d "%SCRIPT_DIR%"

rem 1. Check for TCC (Tiny C Compiler)
where.exe tcc >nul 2>&1
if not errorlevel 1 (
    echo Compiling with TCC...
    if exist launcher.res (
        tcc -mwindows -O2 launcher.c launcher.res -o neovide-launcher.exe -luser32 -lshell32 -ladvapi32
    ) else (
        tcc -mwindows -O2 launcher.c -o neovide-launcher.exe -luser32 -lshell32 -ladvapi32
    )
    if not errorlevel 1 goto :success
)

rem 2. Check for Clang
where.exe clang >nul 2>&1
if not errorlevel 1 (
    echo Compiling with Clang...
    if exist launcher.res (
        clang -mwindows -O2 launcher.c launcher.res -o neovide-launcher.exe -luser32 -lshell32 -ladvapi32
    ) else (
        clang -mwindows -O2 launcher.c -o neovide-launcher.exe -luser32 -lshell32 -ladvapi32
    )
    if not errorlevel 1 goto :success
)

rem 3. Check for GCC (MinGW)
where.exe gcc >nul 2>&1
if not errorlevel 1 (
    echo Compiling with GCC...
    if exist launcher.res (
        gcc -mwindows -O2 launcher.c launcher.res -o neovide-launcher.exe -luser32 -lshell32 -ladvapi32
    ) else (
        gcc -mwindows -O2 launcher.c -o neovide-launcher.exe -luser32 -lshell32 -ladvapi32
    )
    if not errorlevel 1 goto :success
)

rem 4. Fallback to MSVC
set "VCVARS="
if exist "C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools\VC\Auxiliary\Build\vcvars64.bat" (
    set "VCVARS=C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools\VC\Auxiliary\Build\vcvars64.bat"
) else if exist "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat" (
    set "VCVARS=C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat"
) else if exist "C:\Program Files\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat" (
    set "VCVARS=C:\Program Files\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat"
) else if exist "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\vcvars64.bat" (
    set "VCVARS=C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\vcvars64.bat"
) else if exist "C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Auxiliary\Build\vcvars64.bat" (
    set "VCVARS=C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Auxiliary\Build\vcvars64.bat"
)

if "%VCVARS%"=="" (
    echo Error: No supported C compiler found: TCC, Clang, GCC, or MSVC.
    exit /b 1
)

call "%VCVARS%" >nul 2>&1
if errorlevel 1 (
    echo Error: Failed to initialize MSVC environment.
    exit /b 1
)

echo Compiling resource with RC...
rc /nologo launcher.rc
if errorlevel 1 exit /b 1

echo Compiling neovide-launcher.exe with MSVC cl...
cl /nologo /O2 /W3 /DUNICODE /D_UNICODE launcher.c launcher.res /Fe:neovide-launcher.exe /link /SUBSYSTEM:WINDOWS user32.lib shell32.lib advapi32.lib
if errorlevel 1 exit /b 1

del /q launcher.obj >nul 2>&1

:success
echo Build successful: %SCRIPT_DIR%neovide-launcher.exe
endlocal
