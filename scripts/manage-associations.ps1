param(
    [Parameter(Position = 0)]
    [ValidateSet("install", "uninstall", "generate")]
    [string]$Action = "install"
)

$ErrorActionPreference = "Stop"

# 1. Dynamically locate neovide.exe binary
$neovidePath = $null

# Priority 1: Check Windows PATH via where.exe
$whereCmd = where.exe neovide 2>$null
if ($whereCmd) {
    $firstHit = ($whereCmd -split "`r?`n")[0].Trim()
    if ($firstHit -and (Test-Path $firstHit)) {
        # If Scoop shim, read target path from companion .shim file
        $shimPath = [System.IO.Path]::ChangeExtension($firstHit, ".shim")
        if (Test-Path $shimPath) {
            $shimLine = Get-Content $shimPath | Where-Object { $_ -match '^\s*path\s*=\s*"([^"]+)"' }
            if ($shimLine -and $Matches[1] -and (Test-Path $Matches[1])) {
                $neovidePath = $Matches[1]
            }
        }
        if (-not $neovidePath) {
            $item = Get-Item $firstHit
            if ($item.LinkType -eq "SymbolicLink" -or $item.Target) {
                $neovidePath = $item.Target
            } else {
                $neovidePath = $item.FullName
            }
        }
    }
}

# Priority 2: Fallback search locations
if (-not $neovidePath -or -not (Test-Path $neovidePath)) {
    $candidates = @(
        "F:\generic\scoop\apps\neovide\current\neovide.exe",
        "$env:USERPROFILE\scoop\apps\neovide\current\neovide.exe",
        "$env:ProgramFiles\Neovide\neovide.exe",
        "$env:LOCALAPPDATA\Programs\Neovide\neovide.exe"
    )
    foreach ($cand in $candidates) {
        if (Test-Path $cand) {
            $neovidePath = $cand
            break
        }
    }
}

if (-not $neovidePath -or -not (Test-Path $neovidePath)) {
    Write-Error "Could not dynamically locate neovide.exe. Ensure it is in PATH."
    exit 1
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$installReg = Join-Path $scriptDir "neovide-install.reg"
$uninstallReg = Join-Path $scriptDir "neovide-uninstall.reg"
$escapedExe = $neovidePath.Replace('\', '\\')

# List of 143 code/markup/data file extensions
$extensions = @(
    ".ascx", ".asp", ".aspx", ".bash", ".bash_login", ".bash_logout", ".bash_profile", ".bashrc",
    ".bib", ".bowerrc", ".c", ".c++", ".cc", ".cfg", ".cjs", ".clj", ".cljs", ".cljx", ".clojure",
    ".cls", ".cmake", ".code-workspace", ".coffee", ".config", ".containerfile", ".cpp", ".cs",
    ".cshtml", ".csproj", ".css", ".csv", ".csx", ".ctp", ".cxx", ".dart", ".diff", ".dockerfile",
    ".dot", ".dtd", ".editorconfig", ".edn", ".erb", ".eyaml", ".eyml", ".fs", ".fsi", ".fsscript",
    ".fsx", ".gemspec", ".gitattributes", ".gitconfig", ".gitignore", ".go", ".gradle", ".groovy",
    ".h", ".h++", ".handlebars", ".hbs", ".hh", ".hpp", ".htm", ".html", ".hxx", ".ini", ".ipynb",
    ".jade", ".jav", ".java", ".js", ".jscsrc", ".jshintrc", ".jshtm", ".json", ".jsp", ".jsx",
    ".less", ".log", ".lua", ".m", ".makefile", ".markdown", ".md", ".mdoc", ".mdown", ".mdtext",
    ".mdtxt", ".mdwn", ".mjs", ".mk", ".mkd", ".mkdn", ".ml", ".mli", ".npmignore", ".php",
    ".phtml", ".pl", ".pl6", ".plist", ".pm", ".pm6", ".pod", ".pp", ".profile", ".properties",
    ".ps1", ".psd1", ".psgi", ".psm1", ".py", ".pyi", ".r", ".rb", ".rhistory", ".rprofile",
    ".rs", ".rst", ".rt", ".sass", ".scss", ".sh", ".shtml", ".sql", ".svg", ".svgz", ".t",
    ".tex", ".toml", ".ts", ".tsx", ".txt", ".vb", ".vue", ".wxi", ".wxl", ".wxs", ".xaml",
    ".xhtml", ".xml", ".yaml", ".yml", ".zsh"
)

# 2. Build install .reg
$installSb = [System.Text.StringBuilder]::new()
[void]$installSb.AppendLine("Windows Registry Editor Version 5.00`r`n")

# Context Menus
[void]$installSb.AppendLine("; Context Menus")
[void]$installSb.AppendLine("[HKEY_CURRENT_USER\Software\Classes\*\shell\Open with &Neovide]")
[void]$installSb.AppendLine('@="Open with &Neovide"')
[void]$installSb.AppendLine(('"Icon"="\"' + $escapedExe + '\""'))
[void]$installSb.AppendLine("[HKEY_CURRENT_USER\Software\Classes\*\shell\Open with &Neovide\command]")
[void]$installSb.AppendLine(('"@"="\"' + $escapedExe + '\" \"%1\""'))
[void]$installSb.AppendLine("")

[void]$installSb.AppendLine("[HKEY_CURRENT_USER\Software\Classes\Directory\shell\Open with &Neovide]")
[void]$installSb.AppendLine('@="Open with &Neovide"')
[void]$installSb.AppendLine(('"Icon"="\"' + $escapedExe + '\""'))
[void]$installSb.AppendLine("[HKEY_CURRENT_USER\Software\Classes\Directory\shell\Open with &Neovide\command]")
[void]$installSb.AppendLine(('"@"="\"' + $escapedExe + '\" \"%V\""'))
[void]$installSb.AppendLine("")

[void]$installSb.AppendLine("[HKEY_CURRENT_USER\Software\Classes\Directory\Background\shell\Open with &Neovide]")
[void]$installSb.AppendLine('@="Open with &Neovide"')
[void]$installSb.AppendLine(('"Icon"="\"' + $escapedExe + '\""'))
[void]$installSb.AppendLine("[HKEY_CURRENT_USER\Software\Classes\Directory\Background\shell\Open with &Neovide\command]")
[void]$installSb.AppendLine(('"@"="\"' + $escapedExe + '\" \"%V\""'))
[void]$installSb.AppendLine("")

# Portable Application Handler Registration
[void]$installSb.AppendLine("; Portable Application Handler")
[void]$installSb.AppendLine("[HKEY_CURRENT_USER\Software\Classes\Applications\neovide.exe]")
[void]$installSb.AppendLine('"FriendlyAppName"="Neovide"')
[void]$installSb.AppendLine("")

[void]$installSb.AppendLine("[HKEY_CURRENT_USER\Software\Classes\Applications\neovide.exe\DefaultIcon]")
[void]$installSb.AppendLine(('"@"="\"' + $escapedExe + '\",0"'))
[void]$installSb.AppendLine("")

[void]$installSb.AppendLine("[HKEY_CURRENT_USER\Software\Classes\Applications\neovide.exe\shell\open]")
[void]$installSb.AppendLine(('"Icon"="\"' + $escapedExe + '\""'))
[void]$installSb.AppendLine("")

[void]$installSb.AppendLine("[HKEY_CURRENT_USER\Software\Classes\Applications\neovide.exe\shell\open\command]")
[void]$installSb.AppendLine(('"@"="\"' + $escapedExe + '\" \"%1\""'))
[void]$installSb.AppendLine("")

[void]$installSb.AppendLine("[HKEY_CURRENT_USER\Software\Classes\Applications\neovide.exe\SupportedTypes]")
foreach ($ext in $extensions) {
    [void]$installSb.AppendLine(('"' + $ext + '"=""'))
}
[void]$installSb.AppendLine("")

# File Extension Associations
[void]$installSb.AppendLine("; File Extension Associations")
foreach ($ext in $extensions) {
    [void]$installSb.AppendLine(("[HKEY_CURRENT_USER\Software\Classes\" + $ext + "]"))
    [void]$installSb.AppendLine('@="Applications\\neovide.exe"')
    [void]$installSb.AppendLine("")

    [void]$installSb.AppendLine(("[HKEY_CURRENT_USER\Software\Classes\" + $ext + "\OpenWithProgids]"))
    [void]$installSb.AppendLine('"Applications\\neovide.exe"=""')
    [void]$installSb.AppendLine("")
}

[System.IO.File]::WriteAllText($installReg, $installSb.ToString(), [System.Text.Encoding]::Unicode)

# 3. Build uninstall .reg
$uninstallSb = [System.Text.StringBuilder]::new()
[void]$uninstallSb.AppendLine("Windows Registry Editor Version 5.00`r`n")

# Context menus removal
[void]$uninstallSb.AppendLine("; Remove Context Menus")
[void]$uninstallSb.AppendLine("[-HKEY_CURRENT_USER\Software\Classes\*\shell\Open with &Neovide]")
[void]$uninstallSb.AppendLine("[-HKEY_CURRENT_USER\Software\Classes\Directory\shell\Open with &Neovide]")
[void]$uninstallSb.AppendLine("[-HKEY_CURRENT_USER\Software\Classes\Directory\Background\shell\Open with &Neovide]")
[void]$uninstallSb.AppendLine("")

# Portable Application Handler removal
[void]$uninstallSb.AppendLine("; Remove Portable Application Handler")
[void]$uninstallSb.AppendLine("[-HKEY_CURRENT_USER\Software\Classes\Applications\neovide.exe]")
[void]$uninstallSb.AppendLine("")

# File extension associations removal
[void]$uninstallSb.AppendLine("; Remove File Extension Associations")
foreach ($ext in $extensions) {
    [void]$uninstallSb.AppendLine(("[HKEY_CURRENT_USER\Software\Classes\" + $ext + "\OpenWithProgids]"))
    [void]$uninstallSb.AppendLine('"Applications\\neovide.exe"=-')
    [void]$uninstallSb.AppendLine("")

    # Also clean up old synthetic ProgIDs if present
    $progId = "Neovide" + $ext
    [void]$uninstallSb.AppendLine(("[-HKEY_CURRENT_USER\Software\Classes\" + $progId + "]"))
    [void]$uninstallSb.AppendLine("")
}

[System.IO.File]::WriteAllText($uninstallReg, $uninstallSb.ToString(), [System.Text.Encoding]::Unicode)

Write-Host "Resolved Neovide: $neovidePath"
Write-Host "Generated: $installReg"
Write-Host "Generated: $uninstallReg"

# 4. Perform requested action
if ($Action -eq "install") {
    Write-Host "Importing associations and context menu into Registry..."
    Start-Process reg.exe -ArgumentList "import `"$installReg`"" -Wait -NoNewWindow
    Write-Host "Neovide associations successfully installed." -ForegroundColor Green
} elseif ($Action -eq "uninstall") {
    Write-Host "Removing associations and context menu from Registry..."
    Start-Process reg.exe -ArgumentList "import `"$uninstallReg`"" -Wait -NoNewWindow
    Write-Host "Neovide associations successfully removed." -ForegroundColor Yellow
} else {
    Write-Host "Registry files generated. Run with -Action install or -Action uninstall to apply."
}
