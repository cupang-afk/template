# Usage: build.ps1 [compiler]
#   compiler: gcc, clang, tcc, or cl
#
# Selection order:
#   1. compiler argument
#   2. CC environment variable
#   3. first available compiler (gcc, clang, tcc, cl)
#
# Availability is probed by running each compiler with no arguments and
# checking whether it could be started at all (a bare compiler may exit
# nonzero, e.g. "no input files"). For cl, run from a Developer Command
# Prompt.

$ErrorActionPreference = 'Stop'
if (Get-Variable -Name PSNativeCommandUseErrorActionPreference -ErrorAction SilentlyContinue) {
    $PSNativeCommandUseErrorActionPreference = $false
}
Set-Location -LiteralPath $PSScriptRoot

$candidates = @('gcc', 'clang', 'tcc', 'cl')

function Test-Compiler {
    param([string]$Name)

    # Run the compiler with no arguments. A bare compiler can exit nonzero
    # ("no input files"), so availability is decided by whether the command
    # could be started at all, not by its exit code. Native stderr must not
    # be turned into a terminating error (PowerShell 5.1 does that under
    # ErrorActionPreference = Stop).
    $ErrorActionPreference = 'Continue'
    try {
        & $Name *> $null
        return $true
    } catch {
        return $false
    }
}

$requested = if ($args.Count -gt 0 -and $args[0]) { [string]$args[0] } else { $null }
if (-not $requested -and $env:CC) { $requested = $env:CC.Trim() }
if ($requested -ieq 'msvc') { $requested = 'cl' }

if ($requested) {
    if (-not (Test-Compiler $requested)) {
        Write-Error "Compiler '$requested' is not available on PATH. Pass gcc, clang, tcc, or cl, or run from a Developer Command Prompt for cl."
        exit 1
    }
    $compiler = $requested
} else {
    $available = @($candidates | Where-Object { Test-Compiler $_ })
    if ($available.Count -eq 0) {
        Write-Error "No supported compiler found on PATH. Install gcc, clang, or tcc, or run from a Developer Command Prompt for cl."
        exit 1
    }
    $compiler = $available[0]
    Write-Host "Detected: $($available -join ', ')"
    Write-Host "Using $compiler (pass a compiler name as the first argument to override)"
}

$base = [IO.Path]::GetFileNameWithoutExtension($compiler)

if ($base -ieq 'cl') {
    & rc /nologo launcher.rc
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

    & $compiler /nologo /O2 /W3 /DUNICODE /D_UNICODE launcher.c launcher.res /Fe:neovide-launcher.exe /link /SUBSYSTEM:WINDOWS user32.lib
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

    Remove-Item -LiteralPath 'launcher.obj' -ErrorAction SilentlyContinue
} else {
    # Build the icon resource as a COFF object for GNU/TCC linkers.
    if (-not (Test-Path -LiteralPath 'launcher.res.o') -and (Get-Command windres -ErrorAction SilentlyContinue)) {
        & windres launcher.rc -O coff -o launcher.res.o
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    }

    $sources = @('launcher.c')
    if (Test-Path -LiteralPath 'launcher.res.o') { $sources += 'launcher.res.o' }

    # TCC uses -Wl,-subsystem=gui; GCC/Clang use -mwindows.
    $subsystem = if ($base -ieq 'tcc') { '-Wl,-subsystem=gui' } else { '-mwindows' }

    & $compiler $subsystem -O2 @sources -o neovide-launcher.exe -luser32
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

Write-Host "Build successful: $PSScriptRoot\neovide-launcher.exe"
exit 0
