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

func fallbackServer() string {
	return filepath.Join(os.TempDir(), "neovide.sock")
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
