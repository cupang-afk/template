//go:build windows

package main

import (
	"os/exec"
	"syscall"
	"unsafe"
)

func fallbackServer() string {
	return `\\.\pipe\neovide`
}

func probeServer(name string) bool {
	path, err := syscall.UTF16PtrFromString(name)
	if err != nil {
		return false
	}

	ok, _, errno := procWaitNamedPipeW.Call(uintptr(unsafe.Pointer(path)), 80)
	if ok != 0 {
		return true
	}
	// A busy pipe means the server exists but has no free instance.
	return errno == syscall.Errno(231) // ERROR_PIPE_BUSY
}

// hideConsole keeps the short-lived nvim remote command from flashing a window.
func hideConsole(cmd *exec.Cmd) {
	cmd.SysProcAttr = &syscall.SysProcAttr{HideWindow: true}
}

// detach lets Neovide outlive the launcher.
func detach(cmd *exec.Cmd) {
	cmd.SysProcAttr = &syscall.SysProcAttr{HideWindow: false}
}
