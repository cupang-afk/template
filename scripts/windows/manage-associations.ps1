[CmdletBinding()]
param(
    [Parameter()]
    [string]$NeovidePath,
    [Parameter()]
    [switch]$Import,
    [Parameter()]
    [switch]$Uninstall
)

$ErrorActionPreference = 'Stop'

if ($Import -and $Uninstall) {
    throw 'Specify either -Import or -Uninstall, not both.'
}

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

    # Locate via where.exe
    $candidates = [System.Collections.Generic.List[string]]::new()
    $whereHits = where.exe neovide.exe 2>$null
    if ($whereHits) {
        foreach ($hit in ($whereHits -split "`r?`n")) {
            $trimmed = $hit.Trim()
            if (-not $trimmed) { continue }
            if (-not (Test-Path -LiteralPath $trimmed -PathType Leaf)) { continue }
            $resolved = (Resolve-Path -LiteralPath $trimmed).Path
            if (-not $candidates.Contains($resolved)) {
                $candidates.Add($resolved)
            }
        }
    }

    # Selection logic
    $manual = $null

    if ($candidates.Count -gt 0) {
        Write-Host 'Neovide executables found:' -ForegroundColor Cyan
        for ($i = 0; $i -lt $candidates.Count; $i++) {
            Write-Host ("[{0}] {1}" -f ($i + 1), $candidates[$i])
        }
        $selection = Read-Host ("Select [1-{0}], type a full path, or press Enter to browse" -f $candidates.Count)
        $selection = "$selection".Trim().Trim('"')
        $num = 0
        if ([int]::TryParse($selection, [ref]$num) -and $num -ge 1 -and $num -le $candidates.Count) {
            return $candidates[$num - 1]
        }
        $manual = $selection
    } else {
        $manual = Read-Host 'Enter full path to neovide.exe, or press Enter to browse'
        $manual = "$manual".Trim().Trim('"')
    }

    if ($manual -and (Test-Path -LiteralPath $manual -PathType Leaf) -and
        ([IO.Path]::GetFileName($manual) -ieq 'neovide.exe')) {
        return (Resolve-Path -LiteralPath $manual).Path
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

function Test-HasIcon {
    param([Parameter(Mandatory)][string]$Path)

    if (-not ('IconProbe' -as [type])) {
        Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public static class IconProbe {
    [DllImport("shell32.dll", CharSet = CharSet.Unicode)]
    public static extern int ExtractIconEx(string file, int index, IntPtr[] large, IntPtr[] small, int count);
    [DllImport("user32.dll")]
    public static extern bool DestroyIcon(IntPtr handle);
}
'@
    }

    $large = New-Object IntPtr[] 1
    $small = New-Object IntPtr[] 1
    $count = [IconProbe]::ExtractIconEx($Path, 0, $large, $small, 1)
    foreach ($handle in @($large[0], $small[0])) {
        if ($handle -ne [IntPtr]::Zero) {
            [IconProbe]::DestroyIcon($handle) | Out-Null
        }
    }
    return $count -gt 0
}

function Invoke-ShellRefresh {
    if (-not ('ShellRefresh' -as [type])) {
        Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public class ShellRefresh {
    [DllImport("shell32.dll")]
    public static extern void SHChangeNotify(int wEventId, uint uFlags, IntPtr dwItem1, IntPtr dwItem2);
}
'@
    }
    [ShellRefresh]::SHChangeNotify(0x08000000, 0, [IntPtr]::Zero, [IntPtr]::Zero)
}

# .reg files cannot delete a value conditionally, so tidy the shared keys afterwards.
function Invoke-UninstallCleanup {
    param([string[]]$Extensions)

    $currentUser = [Microsoft.Win32.Registry]::CurrentUser
    $fileExtsPath = 'Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts'
    $classesPath = 'Software\Classes'

    $fileExts = $currentUser.OpenSubKey($fileExtsPath, $true)
    $classes = $currentUser.OpenSubKey($classesPath, $true)
    if (-not $fileExts -or -not $classes) {
        if ($fileExts) { $fileExts.Close() }
        if ($classes) { $classes.Close() }
        return
    }

    try {
        foreach ($extension in $Extensions) {
            $appNames = @('neovide.exe', 'neovide-launcher.exe')
            $progId = "Neovide.$extension"

            # Explorer's per-extension MRU list: drop only our values, keep other apps.
            $openWithListPath = ".$extension\OpenWithList"
            $openWithList = $fileExts.OpenSubKey($openWithListPath, $true)
            if ($openWithList) {
                # Drop our entries in case the .reg import did not remove them.
                foreach ($name in @($openWithList.GetValueNames())) {
                    if ($name -eq 'MRUList') { continue }
                    if ($appNames -contains "$($openWithList.GetValue($name))") {
                        $openWithList.DeleteValue($name, $false)
                    }
                }

                # .reg deletes our letter before this runs, so rebuild MRUList by
                # filtering out letters that no longer have a value. This keeps the
                # existing recency order for other applications.
                if ($openWithList.GetValueNames() -contains 'MRUList') {
                    $remaining = @($openWithList.GetValueNames() | Where-Object { $_ -ne 'MRUList' })
                    $mruList = "$($openWithList.GetValue('MRUList'))"
                    $filtered = -join @($mruList.ToCharArray() | Where-Object { $remaining -contains "$_" })
                    if (-not $filtered) {
                        $openWithList.DeleteValue('MRUList', $false)
                    } elseif ($filtered -ne $mruList) {
                        $openWithList.SetValue('MRUList', $filtered)
                    }
                }

                $isEmpty = ($openWithList.GetValueNames().Count -eq 0 -and
                            $openWithList.GetSubKeyNames().Count -eq 0)
                $openWithList.Close()
                if ($isEmpty) {
                    $fileExts.DeleteSubKey($openWithListPath, $false)
                }
            }

            # Remove keys that our value deletions left empty.
            $feProgIds = $fileExts.OpenSubKey(".$extension\OpenWithProgids", $true)
            if ($feProgIds) {
                $isEmpty = ($feProgIds.GetValueNames().Count -eq 0 -and $feProgIds.GetSubKeyNames().Count -eq 0)
                $feProgIds.Close()
                if ($isEmpty) { $fileExts.DeleteSubKey(".$extension\OpenWithProgids", $false) }
            }
            $classProgIds = $classes.OpenSubKey(".$extension\OpenWithProgids", $true)
            if ($classProgIds) {
                $isEmpty = ($classProgIds.GetValueNames().Count -eq 0 -and $classProgIds.GetSubKeyNames().Count -eq 0)
                $classProgIds.Close()
                if ($isEmpty) { $classes.DeleteSubKey(".$extension\OpenWithProgids", $false) }
            }

            $fileExtKey = $fileExts.OpenSubKey(".$extension", $true)
            if ($fileExtKey) {
                $isEmpty = ($fileExtKey.GetValueNames().Count -eq 0 -and
                            $fileExtKey.GetSubKeyNames().Count -eq 0)
                $fileExtKey.Close()
                if ($isEmpty) { $fileExts.DeleteSubKey(".$extension", $false) }
            }
        }
    } finally {
        $fileExts.Close()
        $classes.Close()
    }
}

$extensions = @($FileTypes.Keys | Sort-Object)

if (-not $Uninstall) {
    $exe = Find-Neovide -ExplicitPath $NeovidePath
    $exeReg = ConvertTo-RegString $exe

    # Check for the single-instance launcher.
    $launcherDir = Join-Path $PSScriptRoot 'launcher'
    $launcherExe = Join-Path $launcherDir 'neovide-launcher.exe'
    if (-not (Test-Path $launcherExe)) {
        $buildBat = Join-Path $launcherDir 'build.bat'
        if (Test-Path $buildBat) {
            Write-Host 'Building neovide-launcher.exe...' -ForegroundColor Cyan
            & cmd.exe /c "`"$buildBat`""
        }
    }
    if (-not (Test-Path $launcherExe)) {
        Write-Warning 'neovide-launcher.exe is unavailable; using neovide.exe directly. Build it with scripts\windows\launcher\build.bat <compiler>.'
    }

    $cmdExe = if (Test-Path $launcherExe) { $launcherExe } else { $exe }
    $cmdExeReg = ConvertTo-RegString $cmdExe
    $cmdExeName = [IO.Path]::GetFileName($cmdExe)

    # Icon: use the selected neovide.exe if it has an icon; otherwise fall back to the launcher.
    $iconExe = if (Test-HasIcon $exe) { $exe } else { $cmdExe }
    $iconReg = ConvertTo-RegString $iconExe

    # When the launcher is used, pass the resolved neovide.exe path as its first argument.
    $launchCommand = if ($cmdExe -eq $launcherExe) {
        '@="\"' + $cmdExeReg + '\" \"' + $exeReg + '\" \"%1\""'
    } else {
        '@="\"' + $cmdExeReg + '\" \"%1\""'
    }
    $launchFolderCommand = if ($cmdExe -eq $launcherExe) {
        '@="\"' + $cmdExeReg + '\" \"' + $exeReg + '\" \"%V\""'
    } else {
        '@="\"' + $cmdExeReg + '\" \"%V\""'
    }
}

$outputDirectory = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }

$installAssociations = [System.Collections.Generic.List[string]]::new()
$uninstallAssociations = [System.Collections.Generic.List[string]]::new()
$installContext = [System.Collections.Generic.List[string]]::new()
$uninstallContext = [System.Collections.Generic.List[string]]::new()

$installAssociations.Add('Windows Registry Editor Version 5.00')
$uninstallAssociations.Add('Windows Registry Editor Version 5.00')
$installContext.Add('Windows Registry Editor Version 5.00')
$uninstallContext.Add('Windows Registry Editor Version 5.00')

# Portable application registration & icon definition
if (-not $Uninstall) {
    $installAssociations.Add('')
    $installAssociations.Add("[HKEY_CURRENT_USER\Software\Classes\Applications\$cmdExeName]")
    $installAssociations.Add('"FriendlyAppName"="Neovide"')
    $installAssociations.Add('')
    $installAssociations.Add("[HKEY_CURRENT_USER\Software\Classes\Applications\$cmdExeName\DefaultIcon]")
    $installAssociations.Add('@="' + $iconReg + ',0"')
    $installAssociations.Add('')
    $installAssociations.Add("[HKEY_CURRENT_USER\Software\Classes\Applications\$cmdExeName\shell\open\command]")
    $installAssociations.Add($launchCommand)
    $installAssociations.Add('')
    $installAssociations.Add("[HKEY_CURRENT_USER\Software\Classes\Applications\$cmdExeName\SupportedTypes]")
    foreach ($extension in $extensions) {
        $installAssociations.Add('".' + $extension + '"=""')
    }
}

$uninstallAssociations.Add('')
# Clean up application keys written by this and older versions of the script.
$uninstallAssociations.Add('[-HKEY_CURRENT_USER\Software\Classes\Applications\neovide.exe]')
$uninstallAssociations.Add('[-HKEY_CURRENT_USER\Software\Classes\Applications\neovide-launcher.exe]')

foreach ($extension in $extensions) {
    $progId = "Neovide.$extension"
    $description = ConvertTo-RegString $FileTypes[$extension]

    if (-not $Uninstall) {
        # File class mapping to Application handler
        $installAssociations.Add('')
        $installAssociations.Add("[HKEY_CURRENT_USER\Software\Classes\.$extension]")
        $installAssociations.Add('@="Applications\\' + $cmdExeName + '"')
        $installAssociations.Add('')
        $installAssociations.Add("[HKEY_CURRENT_USER\Software\Classes\.$extension\OpenWithProgids]")
        $installAssociations.Add('"Applications\\' + $cmdExeName + '"=""')
        $installAssociations.Add('"' + $progId + '"=""')
        $installAssociations.Add('')
        $installAssociations.Add("[HKEY_CURRENT_USER\Software\Classes\$progId]")
        $installAssociations.Add('@="' + $description + '"')
        $installAssociations.Add('')
        $installAssociations.Add("[HKEY_CURRENT_USER\Software\Classes\$progId\DefaultIcon]")
        $installAssociations.Add('@="' + $iconReg + ',0"')
        $installAssociations.Add('')
        $installAssociations.Add("[HKEY_CURRENT_USER\Software\Classes\$progId\shell\open\command]")
        $installAssociations.Add($launchCommand)

        # Explorer FileExts MRU binding (matches executable name exactly)
        $installAssociations.Add('')
        $installAssociations.Add("[HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.$extension\OpenWithList]")
        $installAssociations.Add('"a"="' + $cmdExeName + '"')
        $installAssociations.Add('"MRUList"="a"')
        $installAssociations.Add('')
        $installAssociations.Add("[HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.$extension\OpenWithProgids]")
        $installAssociations.Add('"Applications\\' + $cmdExeName + '"=hex(0):')
        $installAssociations.Add('"' + $progId + '"=hex(0):')
    }

    # Uninstallation entries
    $uninstallAssociations.Add('')
    $uninstallAssociations.Add("[HKEY_CURRENT_USER\Software\Classes\.$extension]")
    $uninstallAssociations.Add('@=-')
    $uninstallAssociations.Add('')
    $uninstallAssociations.Add("[HKEY_CURRENT_USER\Software\Classes\.$extension\OpenWithProgids]")
    $uninstallAssociations.Add('"Applications\\neovide.exe"=-')
    $uninstallAssociations.Add('"Applications\\neovide-launcher.exe"=-')
    $uninstallAssociations.Add('"' + $progId + '"=-')
    $uninstallAssociations.Add('')
    $uninstallAssociations.Add("[-HKEY_CURRENT_USER\Software\Classes\$progId]")
    $uninstallAssociations.Add('')
    $uninstallAssociations.Add("[HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.$extension\OpenWithList]")
    $uninstallAssociations.Add('"a"=-')
    $uninstallAssociations.Add('')
    $uninstallAssociations.Add("[HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.$extension\OpenWithProgids]")
    $uninstallAssociations.Add('"Applications\\neovide.exe"=-')
    $uninstallAssociations.Add('"Applications\\neovide-launcher.exe"=-')
    $uninstallAssociations.Add('"' + $progId + '"=-')
}

if (-not $Uninstall) {
    # Right-click a file.
    $installContext.Add('')
    $installContext.Add('[HKEY_CURRENT_USER\Software\Classes\*\shell\Open with Neovide]')
    $installContext.Add('@="Open with Neovide"')
    $installContext.Add('"Icon"="' + $iconReg + ',0"')
    $installContext.Add('[HKEY_CURRENT_USER\Software\Classes\*\shell\Open with Neovide\command]')
    $installContext.Add($launchCommand)

    # Right-click a folder.
    $installContext.Add('')
    $installContext.Add('[HKEY_CURRENT_USER\Software\Classes\Directory\shell\Open with Neovide]')
    $installContext.Add('@="Open with Neovide"')
    $installContext.Add('"Icon"="' + $iconReg + ',0"')
    $installContext.Add('[HKEY_CURRENT_USER\Software\Classes\Directory\shell\Open with Neovide\command]')
    $installContext.Add($launchCommand)

    # Right-click the background inside a folder.
    $installContext.Add('')
    $installContext.Add('[HKEY_CURRENT_USER\Software\Classes\Directory\Background\shell\Open with Neovide]')
    $installContext.Add('@="Open with Neovide"')
    $installContext.Add('"Icon"="' + $iconReg + ',0"')
    $installContext.Add('[HKEY_CURRENT_USER\Software\Classes\Directory\Background\shell\Open with Neovide\command]')
    $installContext.Add($launchFolderCommand)
}

$uninstallContext.Add('')
$uninstallContext.Add('[-HKEY_CURRENT_USER\Software\Classes\*\shell\Open with Neovide]')
$uninstallContext.Add('[-HKEY_CURRENT_USER\Software\Classes\Directory\shell\Open with Neovide]')
$uninstallContext.Add('[-HKEY_CURRENT_USER\Software\Classes\Directory\Background\shell\Open with Neovide]')

$files = [ordered]@{}
if (-not $Uninstall) {
    $files['install-associations.reg'] = $installAssociations
    $files['install-context.reg'] = $installContext
}
$files['uninstall-associations.reg'] = $uninstallAssociations
$files['uninstall-context.reg'] = $uninstallContext

foreach ($name in $files.Keys) {
    $path = Join-Path $outputDirectory $name
    $content = ($files[$name] -join "`r`n") + "`r`n"
    [IO.File]::WriteAllText($path, $content, [Text.Encoding]::Unicode)
}

Write-Host ''
if (-not $Uninstall) {
    Write-Host "Neovide found: $exe" -ForegroundColor Green
}
Write-Host "Generated registry files in: $outputDirectory" -ForegroundColor Green
Write-Host ''

if ($Uninstall) {
    Write-Host 'Removing associations and context menu...' -ForegroundColor Cyan
    Start-Process reg.exe -ArgumentList "import `"$outputDirectory\uninstall-associations.reg`"" -Wait -NoNewWindow
    Start-Process reg.exe -ArgumentList "import `"$outputDirectory\uninstall-context.reg`"" -Wait -NoNewWindow

    # .reg cannot delete keys conditionally, so remove what our value deletions emptied.
    Invoke-UninstallCleanup -Extensions $extensions
    Invoke-ShellRefresh
    Write-Host 'Registry entries successfully removed.' -ForegroundColor Green
} elseif ($Import) {
    Write-Host 'Importing associations and context menu...' -ForegroundColor Cyan
    Start-Process reg.exe -ArgumentList "import `"$outputDirectory\install-associations.reg`"" -Wait -NoNewWindow
    Start-Process reg.exe -ArgumentList "import `"$outputDirectory\install-context.reg`"" -Wait -NoNewWindow

    Invoke-ShellRefresh
    Write-Host 'Registry entries successfully imported.' -ForegroundColor Green
} else {
    Write-Host 'Import install-associations.reg and install-context.reg to apply.'
    Write-Host 'Or run with -Import to apply automatically.'
    Write-Host 'Run with -Uninstall to remove the entries.'
}
