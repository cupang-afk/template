# neovide-launcher

Cross-platform single-instance helper for Neovide.

## Contract

```
neovide-launcher <neovide-executable> [neovide args...]
```

- `argv[1]` is the Neovide executable to start.
- `argv[2..]` are forwarded to Neovide.
- When a live instance is found, `argv[2]` is opened with
  `nvim --server <address> --remote-silent <file>` and the instance is focused.
- With no live instance, Neovide is started with the forwarded arguments.

The launcher never discovers Neovide itself; the caller passes the executable
path. This keeps the launcher independent of install locations and package
managers.

## Build

The launcher is pure Go with no third-party modules.

```sh
# Unix
./build.sh

# Windows
build.bat
```

Cross-compile with the PowerShell wrapper:

```powershell
.\build.ps1 -OS linux -Arch amd64
.\build.ps1 -OS darwin -Arch arm64
.\build.ps1 -OS windows -Arch amd64
```

Cross-compiled binaries are named `neovide-launcher-<os>-<arch>[.exe]` so they
do not overwrite the host build. Go is installed with `scoop install go` on
Windows.

## Instance discovery

The Neovide Lua config starts a per-instance Neovim server and writes its
address to `neovide_active.pipe` in the per-user runtime directory on Unix
(`$XDG_RUNTIME_DIR`, else `$TMPDIR`, else `/tmp`) or the temp directory on
Windows. On `FocusGained` it rewrites the file, so the launcher reuses the most
recently focused instance. On exit it removes the file if it still points at
that instance.

- Windows: named pipes (`\\.\pipe\neovide_<pid>`, fallback `\\.\pipe\neovide`).
- Unix: Unix sockets in `$XDG_RUNTIME_DIR` (`/run/user/<uid>`, mode 0700),
  falling back to `$TMPDIR` and then `/tmp`
  (`neovide_<pid>.sock`, fallback `neovide.sock`).

## Platform behavior

| Platform | Reuse instance | Open file | Focus | New instance |
| --- | --- | --- | --- | --- |
| Windows | yes | yes | Win32 (`SetForegroundWindow`, `SwitchToThisWindow`) | Shift+open prompt |
| Linux | yes | yes | best effort: `xdotool`, `wmctrl`, `swaymsg`, `hyprctl` | `NEOVIDE_LAUNCHER_NEW=1` |
| macOS | yes | yes | best effort: `osascript` / System Events | `NEOVIDE_LAUNCHER_NEW=1` |
| other | yes | yes | no-op | `NEOVIDE_LAUNCHER_NEW=1` |

Two things are inherently limited outside Windows:

- **Shift detection.** A file manager cannot tell the launcher whether Shift was
  held, and there is no portable way to query the keyboard from a GUI process.
  Set `NEOVIDE_LAUNCHER_NEW=1` in the environment of the file-manager action to
  request a separate instance. On a terminal the launcher asks instead.
- **Window focus.** Wayland does not let a third-party client raise an
  arbitrary window, and macOS requires accessibility permission for System
  Events. The launcher tries the common tools and silently continues when the
  compositor refuses; the file is still opened in the running instance.

## Icon

Windows uses `neovide.exe`'s icon when it has one. The bundled `neovide.ico` is
kept for resource embedding; a plain `go build` does not attach it. Generate a
`rsrc.syso` (for example with `go-winres`) before building if the launcher
itself should carry the icon.
