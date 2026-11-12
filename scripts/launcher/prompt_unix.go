//go:build !windows

package main

import (
	"bufio"
	"fmt"
	"os"
	"strings"
)

// A file manager cannot report whether Shift was held, so Unix callers that
// want a separate instance set NEOVIDE_LAUNCHER_NEW=1.
func shiftHeld() bool {
	return os.Getenv("NEOVIDE_LAUNCHER_NEW") == "1"
}

func promptNewInstance() choice {
	if !isTerminal(os.Stdin) {
		return choiceNo
	}

	fmt.Fprint(os.Stderr, "Open in a new Neovide instance? [y/N] ")
	line, err := bufio.NewReader(os.Stdin).ReadString('\n')
	if err != nil {
		return choiceNo
	}

	switch strings.ToLower(strings.TrimSpace(line)) {
	case "y", "yes":
		return choiceYes
	case "c", "cancel", "q", "quit":
		return choiceCancel
	default:
		return choiceNo
	}
}

func isTerminal(file *os.File) bool {
	info, err := file.Stat()
	if err != nil {
		return false
	}
	return info.Mode()&os.ModeCharDevice != 0
}

func notifyError(title, message string) {
	fmt.Fprintf(os.Stderr, "%s: %s\n", title, message)
}
