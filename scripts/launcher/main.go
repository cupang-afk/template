// Command neovide-launcher opens a file in a running Neovide instance when one
// is available, and starts a new instance otherwise.
//
// Contract: neovide-launcher <neovide-executable> [neovide args...]
//
// The first argument is the executable to start. Every remaining argument is
// forwarded to Neovide. When a live instance exists, the first forwarded
// argument is opened through the Neovim server API instead of starting a
// second instance.
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

func main() {
	args := os.Args[1:]
	if len(args) == 0 {
		message := "Usage: neovide-launcher <neovide> [args...]"
		fmt.Fprintln(os.Stderr, message)
		notifyError("Neovide Launcher", message)
		os.Exit(1)
	}

	neovideExe := args[0]
	forwarded := args[1:]

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
			pid, err := spawn(neovideExe, forwarded)
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
	if _, err := spawn(neovideExe, forwarded); err != nil {
		notifyError("Neovide Launcher", err.Error())
		os.Exit(1)
	}
}
