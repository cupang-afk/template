package main

import (
	"context"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"
)

const (
	activeFileName = "neovide_active.pipe"
	remoteTimeout  = 4 * time.Second
)

// activeFilePath is the file the Neovide Lua config writes the most recently
// focused server address to. It lives in the OS temp directory, matching the
// Lua side (vim.env.TMP/TEMP on Windows, TMPDIR on Unix).
func activeFilePath() string {
	return filepath.Join(os.TempDir(), activeFileName)
}

func activeServer() (string, bool) {
	data, err := os.ReadFile(activeFilePath())
	if err == nil {
		server := strings.TrimSpace(string(data))
		if server != "" && probeServer(server) {
			return server, true
		}
	}

	fallback := fallbackServer()
	if probeServer(fallback) {
		return fallback, true
	}

	return "", false
}

// remoteOpen asks the running Neovim instance to edit file. The Neovim CLI is
// the portable API surface: it works with named pipes on Windows and Unix
// sockets everywhere else.
func remoteOpen(server, file string) bool {
	ctx, cancel := context.WithTimeout(context.Background(), remoteTimeout)
	defer cancel()

	cmd := exec.CommandContext(ctx, "nvim", "--server", server, "--remote-silent", file)
	hideConsole(cmd)
	return cmd.Run() == nil
}

// spawn starts Neovide without waiting for it to exit. The child is detached
// so the launcher can return immediately, which is what file managers expect.
func spawn(exe string, args []string) (int, error) {
	cmd := exec.Command(exe, args...)
	detach(cmd)
	if err := cmd.Start(); err != nil {
		return 0, err
	}
	pid := cmd.Process.Pid
	_ = cmd.Process.Release()
	return pid, nil
}

// pidFromServer extracts the PID from a server address of the form
// neovide_<pid> (Windows named pipe or Unix socket path).
func pidFromServer(name string) int {
	index := strings.LastIndex(name, "neovide_")
	if index < 0 {
		return 0
	}

	pid := 0
	for _, r := range name[index+len("neovide_"):] {
		if r < '0' || r > '9' {
			break
		}
		pid = pid*10 + int(r-'0')
	}
	return pid
}
