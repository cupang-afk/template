param(
    [Parameter(Position = 0)]
    [ValidateSet("install", "uninstall", "generate")]
    [string]$Action = "install"
)

$ErrorActionPreference = "Stop"

# 1. Locate Neovide binary dynamically
$neovidePath = $null
$command = Get-Command neovide.exe -ErrorAction SilentlyContinue
if ($command) {
    $neovidePath = $command.Source
}
if (-not $neovidePath -or -not (Test-Path $neovidePath)) {
    # Fallback checks (Scoop default locations)
    $scoopApps = Join-Path $env:USERPROFILE "scoop\apps\neovide\current\neovide.exe"
    $scoopGlobal = "F:\generic\scoop\apps\neovide\current\neovide.exe"
    if (Test-Path $scoopApps) {
        $neovidePath = $scoopApps
    } elseif (Test-Path $scoopGlobal) {
        $neovidePath = $scoopGlobal
    }
}

if (-not $neovidePath -or -not (Test-Path $neovidePath)) {
    Write-Error "neovide.exe could not be found in PATH or standard Scoop directories."
    exit 1
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$installReg = Join-Path $scriptDir "neovide-install.reg"
$uninstallReg = Join-Path $scriptDir "neovide-uninstall.reg"
$openBat = Join-Path $scriptDir "neovide-open.bat"

# Escape backslashes for .reg file format
$escapedExe = $neovidePath.Replace('\', '\\')
$escapedBat = $openBat.Replace('\', '\\')

# List of 143 code/markup/data file extensions matching VS Code associations
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

# Context Menus (Files, Folders, and Folder Backgrounds)
[void]$installSb.AppendLine("; Context Menus")
[void]$installSb.AppendLine("[HKEY_CURRENT_USER\Software\Classes\*\shell\Open with &Neovide]")
[void]$installSb.AppendLine('@="Open with &Neovide"')
[void]$installSb.AppendLine(('"Icon"="\"' + $escapedExe + '\""'))
[void]$installSb.AppendLine("[HKEY_CURRENT_USER\Software\Classes\*\shell\Open with &Neovide\command]")
    [void]$installSb.AppendLine(('"@"="\"' + $escapedBat + '\" \"%1\""'))
    [void]$installSb.AppendLine("")

    [void]$installSb.AppendLine("[HKEY_CURRENT_USER\Software\Classes\Directory\shell\Open with &Neovide]")
    [void]$installSb.AppendLine('@="Open with &Neovide"')
    [void]$installSb.AppendLine(('"Icon"="\"' + $escapedExe + '\""'))
    [void]$installSb.AppendLine("[HKEY_CURRENT_USER\Software\Classes\Directory\shell\Open with &Neovide\command]")
    [void]$installSb.AppendLine(('"@"="\"' + $escapedBat + '\" \"%V\""'))
    [void]$installSb.AppendLine("")

    [void]$installSb.AppendLine("[HKEY_CURRENT_USER\Software\Classes\Directory\Background\shell\Open with &Neovide]")
    [void]$installSb.AppendLine('@="Open with &Neovide"')
    [void]$installSb.AppendLine(('"Icon"="\"' + $escapedExe + '\""'))
    [void]$installSb.AppendLine("[HKEY_CURRENT_USER\Software\Classes\Directory\Background\shell\Open with &Neovide\command]")
    [void]$installSb.AppendLine(('"@"="\"' + $escapedBat + '\" \"%V\""'))
    [void]$installSb.AppendLine("")

    # File Associations
    [void]$installSb.AppendLine("; File Associations")
    foreach ($ext in $extensions) {
        $progId = "Neovide" + $ext
        $cleanExt = $ext.TrimStart('.').ToUpper()

        [void]$installSb.AppendLine(("[HKEY_CURRENT_USER\Software\Classes\" + $ext + "\OpenWithProgids]"))
        [void]$installSb.AppendLine('"Neovide"=""')
        [void]$installSb.AppendLine(('"' + $progId + '"=""'))
        [void]$installSb.AppendLine("")

        [void]$installSb.AppendLine(("[HKEY_CURRENT_USER\Software\Classes\" + $progId + "]"))
        [void]$installSb.AppendLine(('"@"="' + $cleanExt + ' File"'))
        [void]$installSb.AppendLine('"AppUserModelID"="Neovide.Neovide"')
        [void]$installSb.AppendLine("")

        [void]$installSb.AppendLine(("[HKEY_CURRENT_USER\Software\Classes\" + $progId + "\DefaultIcon]"))
        [void]$installSb.AppendLine(('"@"="\"' + $escapedExe + '\""'))
        [void]$installSb.AppendLine("")

        [void]$installSb.AppendLine(("[HKEY_CURRENT_USER\Software\Classes\" + $progId + "\shell\open]"))
        [void]$installSb.AppendLine(('"Icon"="\"' + $escapedExe + '\""'))
        [void]$installSb.AppendLine("")

        [void]$installSb.AppendLine(("[HKEY_CURRENT_USER\Software\Classes\" + $progId + "\shell\open\command]"))
        [void]$installSb.AppendLine(('"@"="\"' + $escapedBat + '\" \"%1\""'))
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
[void]$uninstallSb.AppendLine("[-HKEY_CURRENT_USER\Software\Classes\Directory\Background\shell\Open with &Neovide]`r`n")

# File associations removal
[void]$uninstallSb.AppendLine("; Remove File Associations")
foreach ($ext in $extensions) {
    $progId = "Neovide" + $ext
    [void]$uninstallSb.AppendLine(("[HKEY_CURRENT_USER\Software\Classes\" + $ext + "\OpenWithProgids]"))
    [void]$uninstallSb.AppendLine('"Neovide"=-')
    [void]$uninstallSb.AppendLine(('"' + $progId + '"=-'))
    [void]$uninstallSb.AppendLine("")

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
