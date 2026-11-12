# Usage: build.ps1 [-OS <os>] [-Arch <arch>]
#
# Builds the Go launcher. With no arguments it targets the host OS and
# architecture and writes neovide-launcher[.exe] next to this script.
#
# Cross-compiling writes neovide-launcher-<os>-<arch>[.exe] so the host binary
# is never overwritten:
#
#   .\build.ps1 -OS linux -Arch amd64
#   .\build.ps1 -OS darwin -Arch arm64
#   .\build.ps1 -OS windows -Arch amd64

[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet('windows', 'linux', 'darwin', 'freebsd', 'openbsd', 'netbsd')]
    [string]$OS,

    [Parameter()]
    [ValidateSet('amd64', 'arm64', '386', 'arm')]
    [string]$Arch
)

$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $PSScriptRoot

$go = Get-Command go -ErrorAction SilentlyContinue
if (-not $go) {
    Write-Host 'Go is not installed.' -ForegroundColor Red
    Write-Host 'Install it with: scoop install go'
    exit 1
}

$hostOS = (& go env GOOS).Trim()
$hostArch = (& go env GOARCH).Trim()
if (-not $OS) { $OS = $hostOS }
if (-not $Arch) { $Arch = $hostArch }

$cross = ($OS -ne $hostOS) -or ($Arch -ne $hostArch)

$name = 'neovide-launcher'
if ($cross) { $name += "-$OS-$Arch" }
if ($OS -eq 'windows') { $name += '.exe' }

$ldflags = '-s -w'
if ($OS -eq 'windows') {
    # GUI subsystem: no console window flashes when a file is opened.
    $ldflags += ' -H=windowsgui'
}

$previousCGO = $env:CGO_ENABLED
$previousGOOS = $env:GOOS
$previousGOARCH = $env:GOARCH
try {
    $env:CGO_ENABLED = '0'
    $env:GOOS = $OS
    $env:GOARCH = $Arch

    Write-Host "Building $name for $OS/$Arch..." -ForegroundColor Cyan
    & go build -trimpath -ldflags $ldflags -o $name .
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
} finally {
    $env:CGO_ENABLED = $previousCGO
    $env:GOOS = $previousGOOS
    $env:GOARCH = $previousGOARCH
}

Write-Host "Build successful: $(Join-Path $PSScriptRoot $name)" -ForegroundColor Green
exit 0
