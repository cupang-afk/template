[CmdletBinding()]
param(
    [Parameter()]
    [string]$NeovidePath
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
        throw "The specified path is not neovide.exe: $ExplicitPath"
    }

    # 1. Portable layout: neovide.exe beside script.
    if ($PSScriptRoot) {
        $besideScript = Join-Path $PSScriptRoot 'neovide.exe'
        if (Test-Path -LiteralPath $besideScript -PathType Leaf) {
            return (Resolve-Path -LiteralPath $besideScript).Path
        }

        # 2. Portable layout: neovide.exe in subfolder of script's directory.
        $nearby = @(Get-ChildItem -LiteralPath $PSScriptRoot -Filter 'neovide.exe' -File -Recurse -ErrorAction SilentlyContinue)
        if ($nearby.Count -eq 1) {
            return $nearby[0].FullName
        }
        if ($nearby.Count -gt 1) {
            Write-Host 'Multiple Neovide executables found near this script:'
            for ($i = 0; $i -lt $nearby.Count; $i++) {
                Write-Host ("[{0}] {1}" -f ($i + 1), $nearby[$i].FullName)
            }
            $selection = Read-Host 'Enter the number to use, or press Enter to browse'
            $number = 0
            if ([int]::TryParse($selection, [ref]$number) -and $number -ge 1 -and $number -le $nearby.Count) {
                return $nearby[$number - 1].FullName
            }
        }
    }

    # 3. PATH (includes package-manager shims such as Scoop when configured).
    $command = Get-Command 'neovide.exe' -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($command -and $command.Source -and (Test-Path -LiteralPath $command.Source -PathType Leaf)) {
        return (Resolve-Path -LiteralPath $command.Source).Path
    }

    # 4. Windows App Paths registration.
    $appPathKeys = @(
        'HKCU:\Software\Microsoft\Windows\CurrentVersion\App Paths\neovide.exe',
        'HKLM:\Software\Microsoft\Windows\CurrentVersion\App Paths\neovide.exe'
    )
    foreach ($key in $appPathKeys) {
        if (Test-Path $key) {
            $value = (Get-Item $key).GetValue('')
            if ($value -and (Test-Path -LiteralPath $value -PathType Leaf)) {
                return (Resolve-Path -LiteralPath $value).Path
            }
        }
    }

    # 5. Ask user to locate portable executable.
    Add-Type -AssemblyName System.Windows.Forms
    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.Title = 'Select neovide.exe'
    $dialog.Filter = 'Neovide executable (neovide.exe)|neovide.exe|Executable files (*.exe)|*.exe'
    $dialog.FileName = 'neovide.exe'
    $dialog.CheckFileExists = $true
    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        if ([IO.Path]::GetFileName($dialog.FileName) -ine 'neovide.exe') {
            throw 'Selected file is not named neovide.exe.'
        }
        return (Resolve-Path -LiteralPath $dialog.FileName).Path
    }

    throw 'Neovide could not be located. Run again and provide -NeovidePath.'
}

function Resolve-RealExecutable {
    param([string]$Path)

    if (-not $Path -or -not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return $Path
    }

    # Scoop shim companion .shim contains target binary with icons
    $shim = [IO.Path]::ChangeExtension($Path, '.shim')
    if (Test-Path -LiteralPath $shim -PathType Leaf) {
        $shimContent = Get-Content -LiteralPath $shim -ErrorAction SilentlyContinue
        foreach ($line in $shimContent) {
            if ($line -match '^\s*path\s*=\s*["'']?([^"'']+)["'']?') {
                $target = $Matches[1].Trim()
                if (Test-Path -LiteralPath $target -PathType Leaf) {
                    return (Resolve-Path -LiteralPath $target).Path
                }
            }
        }
    }

    # Symlink / reparse point
    $item = Get-Item -LiteralPath $Path -ErrorAction SilentlyContinue
    if ($item.Target) {
        $target = $item.Target
        if ($target -is [array]) { $target = $target[0] }
        if (Test-Path -LiteralPath $target -PathType Leaf) {
            return (Resolve-Path -LiteralPath $target).Path
        }
    }

    return (Resolve-Path -LiteralPath $Path).Path
}

function ConvertTo-RegString {
    param([Parameter(Mandatory)][string]$Value)
    return $Value.Replace('\', '\\').Replace('"', '\"')
}

$exe = Resolve-RealExecutable (Find-Neovide -ExplicitPath $NeovidePath)
$exeReg = ConvertTo-RegString $exe

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

foreach ($extension in ($FileTypes.Keys | Sort-Object)) {
    $progId = "Neovide.$extension"
    $description = ConvertTo-RegString $FileTypes[$extension]

    $installAssociations.Add('')
    $installAssociations.Add("[HKEY_CURRENT_USER\Software\Classes\.$extension\OpenWithProgids]")
    $installAssociations.Add('"' + $progId + '"=""')
    $installAssociations.Add('')
    $installAssociations.Add("[HKEY_CURRENT_USER\Software\Classes\$progId]")
    $installAssociations.Add('@="' + $description + '"')
    $installAssociations.Add('')
    $installAssociations.Add("[HKEY_CURRENT_USER\Software\Classes\$progId\DefaultIcon]")
    $installAssociations.Add('@="' + $exeReg + ',0"')
    $installAssociations.Add('')
    $installAssociations.Add("[HKEY_CURRENT_USER\Software\Classes\$progId\shell\open\command]")
    $installAssociations.Add('@="\"' + $exeReg + '\" \"%1\""')

    $uninstallAssociations.Add('')
    $uninstallAssociations.Add("[HKEY_CURRENT_USER\Software\Classes\.$extension\OpenWithProgids]")
    $uninstallAssociations.Add('"' + $progId + '"=-')
    $uninstallAssociations.Add('')
    $uninstallAssociations.Add("[-HKEY_CURRENT_USER\Software\Classes\$progId]")
}

# Application registration for Open With and DefaultIcon fallback
$installAssociations.Add('')
$installAssociations.Add('[HKEY_CURRENT_USER\Software\Classes\Applications\neovide.exe]')
$installAssociations.Add('"FriendlyAppName"="Neovide"')
$installAssociations.Add('')
$installAssociations.Add('[HKEY_CURRENT_USER\Software\Classes\Applications\neovide.exe\DefaultIcon]')
$installAssociations.Add('@="' + $exeReg + ',0"')
$installAssociations.Add('')
$installAssociations.Add('[HKEY_CURRENT_USER\Software\Classes\Applications\neovide.exe\shell\open\command]')
$installAssociations.Add('@="\"' + $exeReg + '\" \"%1\""')

$uninstallAssociations.Add('')
$uninstallAssociations.Add('[-HKEY_CURRENT_USER\Software\Classes\Applications\neovide.exe]')

# Right-click a file.
$installContext.Add('')
$installContext.Add('[HKEY_CURRENT_USER\Software\Classes\*\shell\Open with Neovide]')
$installContext.Add('@="Open with Neovide"')
$installContext.Add('"Icon"="' + $exeReg + ',0"')
$installContext.Add('[HKEY_CURRENT_USER\Software\Classes\*\shell\Open with Neovide\command]')
$installContext.Add('@="\"' + $exeReg + '\" \"%1\""')

# Right-click a folder.
$installContext.Add('')
$installContext.Add('[HKEY_CURRENT_USER\Software\Classes\Directory\shell\Open with Neovide]')
$installContext.Add('@="Open with Neovide"')
$installContext.Add('"Icon"="' + $exeReg + ',0"')
$installContext.Add('[HKEY_CURRENT_USER\Software\Classes\Directory\shell\Open with Neovide\command]')
$installContext.Add('@="\"' + $exeReg + '\" \"%1\""')

# Right-click the background inside a folder.
$installContext.Add('')
$installContext.Add('[HKEY_CURRENT_USER\Software\Classes\Directory\Background\shell\Open with Neovide]')
$installContext.Add('@="Open with Neovide"')
$installContext.Add('"Icon"="' + $exeReg + ',0"')
$installContext.Add('[HKEY_CURRENT_USER\Software\Classes\Directory\Background\shell\Open with Neovide\command]')
$installContext.Add('@="\"' + $exeReg + '\" \"%V\""')

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

Write-Host ''
Write-Host "Neovide found: $exe" -ForegroundColor Green
Write-Host "Generated registry files in: $outputDirectory" -ForegroundColor Green
Write-Host ''
Write-Host 'Import install-associations.reg and install-context.reg to install.'
Write-Host 'Import the corresponding uninstall files to remove the entries.'
Write-Host ''
Write-Host 'Note: Windows does not let ordinary registry files choose the default'
Write-Host 'app for each extension. Use Open with > Choose another app > Always'
Write-Host 'open with this app if you also want double-click to launch Neovide.'
