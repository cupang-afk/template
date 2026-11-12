//go:build darwin

package main

import (
	"fmt"
	"os/exec"
	"time"
)

func focusInstance(server string) {
	if pid := pidFromServer(server); pid != 0 {
		focusPID(pid)
	}
}

func focusNewInstance(root int) {
	if root == 0 {
		return
	}

	for attempt := 0; attempt < 100; attempt++ {
		if focusPID(root) {
			return
		}
		time.Sleep(100 * time.Millisecond)
	}
}

// focusPID asks System Events to activate the process. macOS may refuse the
// request when accessibility permissions are missing, so callers treat it as
// best effort.
func focusPID(pid int) bool {
	script := fmt.Sprintf(
		`tell application "System Events" to set frontmost of (first process whose unix id is %d) to true`,
		pid,
	)
	return exec.Command("osascript", "-e", script).Run() == nil
}
