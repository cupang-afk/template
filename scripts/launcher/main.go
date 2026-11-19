// Command neovide-launcher opens a file in a running Neovide instance when one
// is available, and starts a new instance otherwise.
//
// Contract: neovide-launcher <neovide-executable> [--cwd <directory>] [args...]
//
// The first argument is the executable to start. With --cwd, the next argument
// is a directory: the launcher starts a fresh Neovide there with no path
// argument, so the dashboard shows instead of a file explorer. All remaining
// arguments are forwarded to Neovide. Without --cwd, a live instance is reused
// and the first forwarded argument is opened through the Neovim server API.
package main

import (
	"fmt"
	"os"
)

type choice int

const (
	choiceNo choice = iota
	choiceYes
	choiceCancel
)

// launchArgs is the parsed launcher command line.
type launchArgs struct {
	neovide string   // Neovide executable path
	args    []string // arguments forwarded to Neovide
	cwd     string   // when set, start a fresh Neovide in this directory
}

// parseArgs splits the launcher's own flag from the arguments meant for
// Neovide. --cwd must be the first forwarded argument so a file path is never
// mistaken for a flag.
func parseArgs(argv []string) (launchArgs, error) {
	var parsed launchArgs
	if len(argv) == 0 {
		return parsed, fmt.Errorf("Usage: neovide-launcher <neovide> [--cwd <directory>] [args...]")
	}
	parsed.neovide = argv[0]
	rest := argv[1:]

	if len(rest) > 0 && rest[0] == "--cwd" {
		if len(rest) < 2 || rest[1] == "" {
			return parsed, fmt.Errorf("--cwd requires a directory")
		}
		parsed.cwd = rest[1]
		rest = rest[2:]
	}
	parsed.args = rest
	return parsed, nil
}

func main() {
	parsed, err := parseArgs(os.Args[1:])
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		notifyError("Neovide Launcher", err.Error())
		os.Exit(1)
	}

	// A folder open always gets its own instance rooted at that folder. Sending
	// a folder to a live instance makes Neovim open a file explorer instead of
	// the dashboard.
	if parsed.cwd != "" {
		pid, err := spawn(parsed.neovide, parsed.args, parsed.cwd)
		if err != nil {
			notifyError("Neovide Launcher", err.Error())
			return
		}
		focusNewInstance(pid)
		return
	}

	forwarded := parsed.args
	var fileArg string
	if len(forwarded) > 0 {
		fileArg = forwarded[0]
	}

	// Shift (or NEOVIDE_LAUNCHER_NEW on Unix) asks for a separate instance.
	if shiftHeld() {
		switch promptNewInstance() {
		case choiceCancel:
			return
		case choiceYes:
			pid, err := spawn(parsed.neovide, forwarded, "")
			if err != nil {
				notifyError("Neovide Launcher", err.Error())
				return
			}
			focusNewInstance(pid)
			return
		}
	}

	// Reuse the most recently focused instance when its server is alive.
	if server, ok := activeServer(); ok {
		if fileArg == "" {
			focusInstance(server)
			return
		}
		if remoteOpen(server, fileArg) {
			focusInstance(server)
			return
		}
	}

	// No live instance: start Neovide.
	if _, err := spawn(parsed.neovide, forwarded, ""); err != nil {
		notifyError("Neovide Launcher", err.Error())
		os.Exit(1)
	}
}
