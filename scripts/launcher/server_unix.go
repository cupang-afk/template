//go:build !windows

package main

import (
	"net"
	"os"
	"os/exec"
	"path/filepath"
	"syscall"
	"time"
)

// stateDir prefers the per-user runtime directory ($XDG_RUNTIME_DIR, normally
// /run/user/<uid>, mode 0700) and falls back to the temp directory for systems
// without logind. The Lua config resolves the same path.
func stateDir() string {
	for _, dir := range []string{os.Getenv("XDG_RUNTIME_DIR"), os.Getenv("TMPDIR"), "/tmp"} {
		if writableDir(dir) {
			return dir
		}
	}
	return "/tmp"
}

func writableDir(dir string) bool {
	if dir == "" {
		return false
	}

	file, err := os.CreateTemp(dir, ".neovide-launcher-*")
	if err != nil {
		return false
	}
	name := file.Name()
	_ = file.Close()
	_ = os.Remove(name)
	return true
}

func fallbackServer() string {
	return filepath.Join(stateDir(), "neovide.sock")
}

func probeServer(name string) bool {
	conn, err := net.DialTimeout("unix", name, 80*time.Millisecond)
	if err != nil {
		return false
	}
	_ = conn.Close()
	return true
}

func hideConsole(*exec.Cmd) {}

// detach puts Neovide in its own session so it survives the launcher.
func detach(cmd *exec.Cmd) {
	cmd.SysProcAttr = &syscall.SysProcAttr{Setsid: true}
}
