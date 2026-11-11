[CmdletBinding()]
param(
    [Parameter()]
    [string]$NeovidePath,
    [Parameter()]
    [switch]$Import
)

$ErrorActionPreference = 'Stop'

# File types copied from supplied VS Code association list.
$FileTypes = @{
    'ascx'           = 'ASCX Source File'
    'asp'            = 'ASP Source File'
    'aspx'           = 'ASPX Source File'
    'bash'           = 'Bash Source File'
    'bash_login'     = 'Bash Login Source File'
    'bash_logout'    = 'Bash Logout Source File'
    'bash_profile'   = 'Bash Profile Source File'
    'bashrc'         = 'Bash RC Source File'
    'bib'            = 'BibTeX Source File'
    'bowerrc'        = 'Bower RC Source File'
    'c'              = 'C Source File'
    'c++'            = 'C++ Source File'
    'cc'             = 'C++ Source File'
    'cfg'            = 'Configuration Source File'
    'cjs'            = 'JavaScript Source File'
    'clj'            = 'Clojure Source File'
    'cljs'           = 'ClojureScript Source File'
    'cljx'           = 'CLJX Source File'
    'clojure'        = 'Clojure Source File'
    'cls'            = 'LaTeX Source File'
    'cmake'          = 'CMake Source File'
    'code-workspace' = 'Code Workspace Source File'
    'coffee'         = 'CoffeeScript Source File'
    'config'         = 'Configuration Source File'
    'containerfile'  = 'Containerfile Source File'
    'cpp'            = 'C++ Source File'
    'cs'             = 'C# Source File'
    'cshtml'         = 'CSHTML Source File'
    'csproj'         = 'C# Project Source File'
    'css'            = 'CSS Source File'
    'csv'            = 'Comma Separated Values Source File'
    'csx'            = 'C# Script Source File'
    'ctp'            = 'CakePHP Template Source File'
    'cxx'            = 'C++ Source File'
    'dart'           = 'Dart Source File'
    'diff'           = 'Diff Source File'
    'dockerfile'     = 'Dockerfile Source File'
    'dot'            = 'Dot Source File'
    'dtd'            = 'Document Type Definition Source File'
    'editorconfig'   = 'Editor Config Source File'
    'edn'            = 'Extensible Data Notation Source File'
    'erb'            = 'Ruby Source File'
    'eyaml'          = 'Hiera Eyaml Source File'
    'eyml'           = 'Hiera Eyaml Source File'
    'fs'             = 'F# Source File'
    'fsi'            = 'F# Signature Source File'
    'fsscript'       = 'F# Script Source File'
    'fsx'            = 'F# Script Source File'
    'gemspec'        = 'Gemspec Source File'
    'gitattributes'  = 'Git Attributes Source File'
    'gitconfig'      = 'Git Config Source File'
    'gitignore'      = 'Git Ignore Source File'
    'go'             = 'Go Source File'
    'gradle'         = 'Gradle Source File'
    'groovy'         = 'Groovy Source File'
    'h'              = 'C Header Source File'
    'h++'            = 'C++ Header Source File'
    'handlebars'     = 'Handlebars Source File'
    'hbs'            = 'Handlebars Source File'
    'hh'             = 'C++ Header Source File'
    'hpp'            = 'C++ Header Source File'
    'htm'            = 'HTML Source File'
    'html'           = 'HTML Source File'
    'hxx'            = 'C++ Header Source File'
    'ini'            = 'INI Source File'
    'ipynb'          = 'Jupyter Source File'
    'jade'           = 'Jade Source File'
    'jav'            = 'Java Source File'
    'java'           = 'Java Source File'
    'js'             = 'JavaScript Source File'
    'jscsrc'         = 'JSCS RC Source File'
    'jshintrc'       = 'JSHint RC Source File'
    'jshtm'          = 'JavaScript HTML Template Source File'
    'json'           = 'JSON Source File'
    'jsp'            = 'Java Server Pages Source File'
    'jsx'            = 'JavaScript Source File'
    'less'           = 'LESS Source File'
    'log'            = 'Log file Source File'
    'lua'            = 'Lua Source File'
    'm'              = 'Objective C Source File'
    'makefile'       = 'Makefile Source File'
    'markdown'       = 'Markdown Source File'
    'md'             = 'Markdown Source File'
    'mdoc'           = 'MDoc Source File'
    'mdown'          = 'Markdown Source File'
    'mdtext'         = 'Markdown Source File'
    'mdtxt'          = 'Markdown Source File'
    'mdwn'           = 'Markdown Source File'
    'mjs'            = 'JavaScript Source File'
    'mk'             = 'Makefile Source File'
    'mkd'            = 'Markdown Source File'
    'mkdn'           = 'Markdown Source File'
    'ml'             = 'OCaml Source File'
    'mli'            = 'OCaml Source File'
    'npmignore'      = 'NPM Ignore Source File'
    'php'            = 'PHP Source File'
    'phtml'          = 'PHP HTML Source File'
    'pl'             = 'Perl Source File'
    'pl6'            = 'Perl 6 Source File'
    'plist'          = 'Properties file Source File'
    'pm'             = 'Perl Module Source File'
    'pm6'            = 'Perl 6 Module Source File'
    'pod'            = 'Perl POD Source File'
    'pp'             = 'Perl Source File'
    'profile'        = 'Profile Source File'
    'properties'     = 'Properties Source File'
    'ps1'            = 'PowerShell Source File'
    'psd1'           = 'PowerShell Module Manifest Source File'
    'psgi'           = 'Perl CGI Source File'
    'psm1'           = 'PowerShell Module Source File'
    'py'             = 'Python Source File'
    'pyi'            = 'Python Source File'
    'r'              = 'R Source File'
    'rb'             = 'Ruby Source File'
    'rhistory'       = 'R History Source File'
    'rprofile'       = 'R Profile Source File'
    'rs'             = 'Rust Source File'
    'rst'            = 'Restructured Text Source File'
    'rt'             = 'Rich Text Source File'
    'sass'           = 'Sass Source File'
    'scss'           = 'Sass Source File'
    'sh'             = 'SH Source File'
    'shtml'          = 'SHTML Source File'
    'sql'            = 'SQL Source File'
    'svg'            = 'SVG Source File'
    'svgz'           = 'SVGZ Source File'
    't'              = 'Perl Source File'
    'tex'            = 'LaTeX Source File'
    'toml'           = 'Toml Source File'
    'ts'             = 'TypeScript Source File'
    'tsx'            = 'TypeScript Source File'
    'txt'            = 'Text Source File'
    'vb'             = 'Visual Basic Source File'
    'vue'            = 'VUE Source File'
    'wxi'            = 'WiX Include Source File'
    'wxl'            = 'WiX Localization Source File'
    'wxs'            = 'WiX Source File'
    'xaml'           = 'XAML Source File'
    'xhtml'          = 'HTML Source File'
    'xml'            = 'XML Source File'
    'yaml'           = 'Yaml Source File'
    'yml'            = 'Yaml Source File'
    'zsh'            = 'ZSH Source File'
}

function Find-Neovide {
    param([string]$ExplicitPath)

    if ($ExplicitPath) {
        $candidate = (Resolve-Path -LiteralPath $ExplicitPath -ErrorAction Stop).Path
        if ((Test-Path -LiteralPath $candidate -PathType Leaf) -and
            ([IO.Path]::GetFileName($candidate) -ieq 'neovide.exe')) {
            return $candidate
        }
        throw "The specified path is not a valid neovide.exe: $ExplicitPath"
    }

    $raw = @()

    # 1. Portable layout: beside script or in subfolders
    if ($PSScriptRoot) {
        $raw += Join-Path $PSScriptRoot 'neovide.exe'
        $raw += @(Get-ChildItem -LiteralPath $PSScriptRoot -Filter 'neovide.exe' -File -Recurse -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName)
    }

    # 2. PATH via where.exe
    $whereHits = where.exe neovide 2>$null
    if ($whereHits) {
        $raw += ($whereHits -split "`r?`n")
    }

    # 3. Known installation locations
    $raw += @(
        'F:\generic\scoop\apps\neovide\current\neovide.exe',
        "$env:USERPROFILE\scoop\apps\neovide\current\neovide.exe",
        "$env:ProgramFiles\Neovide\neovide.exe",
        "${env:ProgramFiles(x86)}\Neovide\neovide.exe",
        "$env:LOCALAPPDATA\Programs\Neovide\neovide.exe"
    )

    # 4. Windows App Paths
    $appPathKeys = @(
        'HKCU:\Software\Microsoft\Windows\CurrentVersion\App Paths\neovide.exe',
        'HKLM:\Software\Microsoft\Windows\CurrentVersion\App Paths\neovide.exe'
    )
    foreach ($key in $appPathKeys) {
        if (Test-Path $key) {
            $raw += (Get-Item $key).GetValue('')
        }
    }

    # 5. Filter: must exist, named neovide.exe, deduplicate
    $candidates = [System.Collections.Generic.List[string]]::new()
    foreach ($item in $raw) {
        if (-not $item) { continue }
        $trimmed = $item.Trim()
        if (-not (Test-Path -LiteralPath $trimmed -PathType Leaf)) { continue }
        if ([IO.Path]::GetFileName($trimmed) -ine 'neovide.exe') { continue }
        $resolved = (Resolve-Path -LiteralPath $trimmed).Path
        if (-not $candidates.Contains($resolved)) {
            $candidates.Add($resolved)
        }
    }

    # Selection logic
    if ($candidates.Count -eq 1) {
        return $candidates[0]
    }

    if ($candidates.Count -gt 1) {
        Write-Host 'Multiple Neovide executables found:' -ForegroundColor Cyan
        for ($i = 0; $i -lt $candidates.Count; $i++) {
            Write-Host ("[{0}] {1}" -f ($i + 1), $candidates[$i])
        }
        $selection = Read-Host ("Select executable [1-{0}] or press Enter to browse" -f $candidates.Count)
        $num = 0
        if ([int]::TryParse($selection, [ref]$num) -and $num -ge 1 -and $num -le $candidates.Count) {
            return $candidates[$num - 1]
        }
    }

    # 0 found or user pressed Enter
    Add-Type -AssemblyName System.Windows.Forms
    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.Title = 'Select neovide.exe'
    $dialog.Filter = 'Neovide executable (neovide.exe)|neovide.exe'
    $dialog.FileName = 'neovide.exe'
    $dialog.CheckFileExists = $true
    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        if ([IO.Path]::GetFileName($dialog.FileName) -ieq 'neovide.exe') {
            return (Resolve-Path -LiteralPath $dialog.FileName).Path
        }
        throw 'The selected file is not named neovide.exe.'
    }

    throw 'Neovide was not located. Provide -NeovidePath.'
}

function ConvertTo-RegString {
    param([Parameter(Mandatory)][string]$Value)
    return $Value.Replace('\', '\\').Replace('"', '\"')
}

$exe = Find-Neovide -ExplicitPath $NeovidePath
$exeReg = ConvertTo-RegString $exe

# Check for custom C single-instance launcher
$launcherDir = Join-Path $PSScriptRoot "launcher"
$launcherExe = Join-Path $launcherDir "neovide-launcher.exe"
if (-not (Test-Path $launcherExe)) {
    $buildBat = Join-Path $launcherDir "build.bat"
    if (Test-Path $buildBat) {
        Write-Host "Building C neovide-launcher.exe..." -ForegroundColor Cyan
        & cmd.exe /c "`"$buildBat`""
    }
}

$cmdExe = if (Test-Path $launcherExe) { $launcherExe } else { $exe }
$cmdExeReg = ConvertTo-RegString $cmdExe

$outputDirectory = $PSScriptRoot
if (-not $outputDirectory) {
    $outputDirectory = (Get-Location).Path
}

$installAssociations = [System.Collections.Generic.List[string]]::new()
$uninstallAssociations = [System.Collections.Generic.List[string]]::new()
$installContext = [System.Collections.Generic.List[string]]::new()
$uninstallContext = [System.Collections.Generic.List[string]]::new()

$installAssociations.Add('Windows Registry Editor Version 5.00')
$uninstallAssociations.Add('Windows Registry Editor Version 5.00')
$installContext.Add('Windows Registry Editor Version 5.00')
$uninstallContext.Add('Windows Registry Editor Version 5.00')

# Portable application registration & icon definition
$installAssociations.Add('')
$installAssociations.Add('[HKEY_CURRENT_USER\Software\Classes\Applications\neovide.exe]')
$installAssociations.Add('"FriendlyAppName"="Neovide"')
$installAssociations.Add('')
$installAssociations.Add('[HKEY_CURRENT_USER\Software\Classes\Applications\neovide.exe\DefaultIcon]')
$installAssociations.Add('@="' + $exeReg + ',0"')
$installAssociations.Add('')
$installAssociations.Add('[HKEY_CURRENT_USER\Software\Classes\Applications\neovide.exe\shell\open\command]')
$installAssociations.Add('@="\"' + $cmdExeReg + '\" \"%1\""')
$installAssociations.Add('')
$installAssociations.Add('[HKEY_CURRENT_USER\Software\Classes\Applications\neovide.exe\SupportedTypes]')
foreach ($extension in ($FileTypes.Keys | Sort-Object)) {
    $installAssociations.Add('".' + $extension + '"=""')
}

$uninstallAssociations.Add('')
$uninstallAssociations.Add('[-HKEY_CURRENT_USER\Software\Classes\Applications\neovide.exe]')

foreach ($extension in ($FileTypes.Keys | Sort-Object)) {
    $progId = "Neovide.$extension"
    $description = ConvertTo-RegString $FileTypes[$extension]

    # File class mapping to Application handler
    $installAssociations.Add('')
    $installAssociations.Add("[HKEY_CURRENT_USER\Software\Classes\.$extension]")
    $installAssociations.Add('@="Applications\\neovide.exe"')
    $installAssociations.Add('')
    $installAssociations.Add("[HKEY_CURRENT_USER\Software\Classes\.$extension\OpenWithProgids]")
    $installAssociations.Add('"Applications\\neovide.exe"=""')
    $installAssociations.Add('"' + $progId + '"=""')
    $installAssociations.Add('')
    $installAssociations.Add("[HKEY_CURRENT_USER\Software\Classes\$progId]")
    $installAssociations.Add('@="' + $description + '"')
    $installAssociations.Add('')
    $installAssociations.Add("[HKEY_CURRENT_USER\Software\Classes\$progId\DefaultIcon]")
    $installAssociations.Add('@="' + $exeReg + ',0"')
    $installAssociations.Add('')
    $installAssociations.Add("[HKEY_CURRENT_USER\Software\Classes\$progId\shell\open\command]")
    $installAssociations.Add('@="\"' + $cmdExeReg + '\" \"%1\""')

    # Explorer FileExts MRU binding (prevents "How do you want to open this file?" dialog)
    $installAssociations.Add('')
    $installAssociations.Add("[HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.$extension\OpenWithList]")
    $installAssociations.Add('"a"="neovide.exe"')
    $installAssociations.Add('"MRUList"="a"')
    $installAssociations.Add('')
    $installAssociations.Add("[HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.$extension\OpenWithProgids]")
    $installAssociations.Add('"Applications\\neovide.exe"=hex(0):')

    # Uninstallation entries
    $uninstallAssociations.Add('')
    $uninstallAssociations.Add("[HKEY_CURRENT_USER\Software\Classes\.$extension\OpenWithProgids]")
    $uninstallAssociations.Add('"Applications\\neovide.exe"=-')
    $uninstallAssociations.Add('"' + $progId + '"=-')
    $uninstallAssociations.Add('')
    $uninstallAssociations.Add("[-HKEY_CURRENT_USER\Software\Classes\$progId]")
    $uninstallAssociations.Add('')
    $uninstallAssociations.Add("[HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.$extension\OpenWithList]")
    $uninstallAssociations.Add('"a"=-')
    $uninstallAssociations.Add('"MRUList"=-')
    $uninstallAssociations.Add('')
    $uninstallAssociations.Add("[HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.$extension\OpenWithProgids]")
    $uninstallAssociations.Add('"Applications\\neovide.exe"=-')
}

# Right-click a file.
$installContext.Add('')
$installContext.Add('[HKEY_CURRENT_USER\Software\Classes\*\shell\Open with Neovide]')
$installContext.Add('@="Open with Neovide"')
$installContext.Add('"Icon"="' + $exeReg + ',0"')
$installContext.Add('[HKEY_CURRENT_USER\Software\Classes\*\shell\Open with Neovide\command]')
$installContext.Add('@="\"' + $cmdExeReg + '\" \"%1\""')

# Right-click a folder.
$installContext.Add('')
$installContext.Add('[HKEY_CURRENT_USER\Software\Classes\Directory\shell\Open with Neovide]')
$installContext.Add('@="Open with Neovide"')
$installContext.Add('"Icon"="' + $exeReg + ',0"')
$installContext.Add('[HKEY_CURRENT_USER\Software\Classes\Directory\shell\Open with Neovide\command]')
$installContext.Add('@="\"' + $cmdExeReg + '\" \"%1\""')

# Right-click the background inside a folder.
$installContext.Add('')
$installContext.Add('[HKEY_CURRENT_USER\Software\Classes\Directory\Background\shell\Open with Neovide]')
$installContext.Add('@="Open with Neovide"')
$installContext.Add('"Icon"="' + $exeReg + ',0"')
$installContext.Add('[HKEY_CURRENT_USER\Software\Classes\Directory\Background\shell\Open with Neovide\command]')
$installContext.Add('@="\"' + $cmdExeReg + '\" \"%V\""')

$uninstallContext.Add('')
$uninstallContext.Add('[-HKEY_CURRENT_USER\Software\Classes\*\shell\Open with Neovide]')
$uninstallContext.Add('[-HKEY_CURRENT_USER\Software\Classes\Directory\shell\Open with Neovide]')
$uninstallContext.Add('[-HKEY_CURRENT_USER\Software\Classes\Directory\Background\shell\Open with Neovide]')

$files = @{
    'install-associations.reg'   = $installAssociations
    'uninstall-associations.reg' = $uninstallAssociations
    'install-context.reg'        = $installContext
    'uninstall-context.reg'      = $uninstallContext
}

foreach ($name in $files.Keys) {
    $path = Join-Path $outputDirectory $name
    $content = ($files[$name] -join "`r`n") + "`r`n"
    [IO.File]::WriteAllText($path, $content, [Text.Encoding]::Unicode)
}

# Invalidate Windows Explorer icon & association cache
Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public class ShellRefresh {
    [DllImport("shell32.dll")]
    public static extern void SHChangeNotify(int wEventId, uint uFlags, IntPtr dwItem1, IntPtr dwItem2);
}
'@ -ErrorAction SilentlyContinue
[ShellRefresh]::SHChangeNotify(0x08000000, 0, [IntPtr]::Zero, [IntPtr]::Zero)

Write-Host ''
Write-Host "Neovide found: $exe" -ForegroundColor Green
Write-Host "Generated registry files in: $outputDirectory" -ForegroundColor Green
Write-Host ''

if ($Import) {
    Write-Host 'Importing associations and context menu...' -ForegroundColor Cyan
    Start-Process reg.exe -ArgumentList "import `"`"$outputDirectory\install-associations.reg`"`"" -Wait -NoNewWindow
    Start-Process reg.exe -ArgumentList "import `"`"$outputDirectory\install-context.reg`"`"" -Wait -NoNewWindow
    [ShellRefresh]::SHChangeNotify(0x08000000, 0, [IntPtr]::Zero, [IntPtr]::Zero)
    Write-Host 'Registry entries successfully imported.' -ForegroundColor Green
} else {
    Write-Host 'Import install-associations.reg and install-context.reg to apply.'
    Write-Host 'Or run with -Import to apply automatically.'
}
