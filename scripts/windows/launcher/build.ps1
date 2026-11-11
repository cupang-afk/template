# Usage: build.ps1 [compiler]
#   compiler: gcc, clang, tcc, or cl
#
# Selection order:
#   1. compiler argument
#   2. CC environment variable
#   3. first available compiler (gcc, clang, tcc, cl)
#
# If no compiler is found, offers to download a portable TCC automatically.
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

# Write-Error would raise a terminating error under ErrorActionPreference = Stop
# and print a stack trace; this keeps the message and exit code clean.
function Fail {
    param([string]$Message)
    Write-Host $Message -ForegroundColor Red
    exit 1
}

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

$TccVersion = '0.9.27'
$TccUrl = "https://download.savannah.gnu.org/releases/tinycc/tcc-$TccVersion-win64-bin.zip"
$TccSha256 = '34A721949A2583FDFF725312DA092FA0F5F1F284B702E6F811C6954714FAABB2'

# Keep the portable toolchain next to the sources so it can be deleted with them.
$TccDir = Join-Path $PSScriptRoot 'tcc'
$TccExe = Join-Path $TccDir 'tcc.exe'

# Checksum and unzip use .NET Framework types instead of Get-FileHash and
# Expand-Archive. When build.bat is started from cmd, the inherited
# PSModulePath can point at PowerShell 7's modules, and Windows PowerShell 5.1
# then auto-loads Microsoft.PowerShell.Utility 7.0.0.0, which does not provide
# Get-FileHash.
function Get-Sha256Hex {
    param([string]$Path)

    $sha = [Security.Cryptography.SHA256]::Create()
    try {
        $stream = [IO.File]::OpenRead($Path)
        try {
            $bytes = $sha.ComputeHash($stream)
        } finally {
            $stream.Dispose()
        }
    } finally {
        $sha.Dispose()
    }
    return ([BitConverter]::ToString($bytes) -replace '-', '')
}

function Save-Url {
    param([string]$Url, [string]$Path)

    # curl.exe ships with Windows 10 1803+ and is faster than Invoke-WebRequest.
    # Use the .exe name explicitly: in Windows PowerShell, "curl" is an alias
    # for Invoke-WebRequest.
    $curl = Get-Command curl.exe -ErrorAction SilentlyContinue
    if ($curl) {
        & $curl.Source --fail --location --silent --show-error --output $Path $Url
        if ($LASTEXITCODE -ne 0) {
            throw "curl.exe failed with exit code $LASTEXITCODE"
        }
        return
    }

    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $Url -OutFile $Path -UseBasicParsing
}

function Expand-Zip {
    param([string]$Path, [string]$Destination)

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [IO.Compression.ZipFile]::ExtractToDirectory($Path, $Destination)
}

function Install-Tcc {
    if (Test-Path -LiteralPath $TccExe) {
        Write-Host "Using downloaded TCC: $TccExe"
        return $TccExe
    }

    Write-Host "Downloading TCC $TccVersion..." -ForegroundColor Cyan
    Write-Host "  $TccUrl"

    $tempDir = Join-Path ([IO.Path]::GetTempPath()) ('tcc-' + [Guid]::NewGuid().ToString('N'))
    $zip = Join-Path $tempDir 'tcc.zip'
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

    try {
        Save-Url -Url $TccUrl -Path $zip
        $hash = Get-Sha256Hex -Path $zip
        if ($hash -ne $TccSha256) {
            throw "checksum mismatch (expected $TccSha256, got $hash)"
        }

        Expand-Zip -Path $zip -Destination $tempDir
        $extracted = Join-Path $tempDir 'tcc'
        if (-not (Test-Path -LiteralPath (Join-Path $extracted 'tcc.exe'))) {
            throw 'unexpected archive layout'
        }

        New-Item -ItemType Directory -Path $PSScriptRoot -Force | Out-Null
        Copy-Item -LiteralPath $extracted -Destination $PSScriptRoot -Recurse -Force
    } finally {
        Remove-Item -LiteralPath $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    }

    if (-not (Test-Path -LiteralPath $TccExe)) {
        throw "TCC was extracted but $TccExe is missing"
    }
    Write-Host "TCC installed to $TccDir" -ForegroundColor Green
    return $TccExe
}

$requested = if ($args.Count -gt 0 -and $args[0]) { [string]$args[0] } else { $null }
if (-not $requested -and $env:CC) { $requested = $env:CC.Trim() }
if ($requested -ieq 'msvc') { $requested = 'cl' }

if ($requested) {
    if (-not (Test-Compiler $requested)) {
        Fail "Compiler '$requested' is not available on PATH. Pass gcc, clang, tcc, or cl, or run from a Developer Command Prompt for cl."
    }
    $compiler = $requested
} else {
    $available = @($candidates | Where-Object { Test-Compiler $_ })
    if ($available.Count -eq 0) {
        if (Test-Path -LiteralPath $TccExe) {
            $compiler = $TccExe
            Write-Host "No supported compiler found on PATH; using previously downloaded TCC: $TccExe"
        } else {
            Write-Host 'No supported compiler found on PATH.' -ForegroundColor Yellow
            Write-Host ''
            Write-Host 'TCC is a small, portable option that needs no installation:' -ForegroundColor Yellow
            Write-Host "  $TccUrl"
            Write-Host ''
            $answer = "$(Read-Host 'Download and use portable TCC automatically? [Y/n]')".Trim()
            if ($answer -and $answer -notmatch '^[Yy]') {
                Fail 'Install gcc, clang, or tcc, or run from a Developer Command Prompt for cl.'
            }
            try {
                $compiler = Install-Tcc
            } catch {
                Fail "Automatic TCC download failed: $($_.Exception.Message)`nInstall gcc, clang, or tcc, or run from a Developer Command Prompt for cl."
            }
            Write-Host "Using $compiler (downloaded automatically)"
        }
    } else {
        $compiler = $available[0]
        Write-Host "Detected: $($available -join ', ')"
        Write-Host "Using $compiler (pass a compiler name as the first argument to override)"
    }
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
