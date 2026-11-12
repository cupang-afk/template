//go:build linux

package main

import (
	"fmt"
	"os"
	"os/exec"
	"strconv"
	"strings"
	"time"
)

// focusInstance walks up the process tree because the server may be owned by a
// wrapper process rather than the process that owns the window.
func focusInstance(server string) {
	pid := pidFromServer(server)
	if pid == 0 {
		return
	}

	for depth := 0; depth < 16 && pid > 1; depth++ {
		if focusPID(pid) {
			return
		}
		pid = parentPid(pid)
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

func parentPid(pid int) int {
	data, err := os.ReadFile(fmt.Sprintf("/proc/%d/stat", pid))
	if err != nil {
		return 0
	}

	// The comm field can contain spaces and parentheses; parse after the last ')'.
	stat := string(data)
	end := strings.LastIndex(stat, ")")
	if end < 0 {
		return 0
	}

	fields := strings.Fields(stat[end+1:])
	if len(fields) < 2 {
		return 0
	}

	ppid, err := strconv.Atoi(fields[1])
	if err != nil {
		return 0
	}
	return ppid
}

// focusPID tries the common X11 and Wayland compositor tools. Wayland does not
// allow a third-party client to raise an arbitrary window, so this is the best
// effort the platform permits.
func focusPID(pid int) bool {
	target := strconv.Itoa(pid)

	if have("xdotool") &&
		run("xdotool", "search", "--onlyvisible", "--pid", target, "windowactivate", "--sync") {
		return true
	}

	if have("wmctrl") {
		if id := wmctrlID(pid); id != "" && run("wmctrl", "-ia", id) {
			return true
		}
	}

	if have("swaymsg") && run("swaymsg", fmt.Sprintf("[pid=%d] focus", pid)) {
		return true
	}

	if have("hyprctl") && run("hyprctl", "dispatch", "focuswindow", "pid:"+target) {
		return true
	}

	return false
}

func wmctrlID(pid int) string {
	output, err := exec.Command("wmctrl", "-lp").Output()
	if err != nil {
		return ""
	}

	target := strconv.Itoa(pid)
	for _, line := range strings.Split(string(output), "\n") {
		fields := strings.Fields(line)
		if len(fields) >= 3 && fields[2] == target {
			return fields[0]
		}
	}
	return ""
}

func have(name string) bool {
	_, err := exec.LookPath(name)
	return err == nil
}

func run(name string, args ...string) bool {
	return exec.Command(name, args...).Run() == nil
}
