package main

import (
	"reflect"
	"testing"
)

func TestPidFromServer(t *testing.T) {
	tests := []struct {
		server string
		want   int
	}{
		{`\\.\pipe\neovide_1234`, 1234},
		{`/tmp/neovide_42.sock`, 42},
		{`\\.\pipe\neovide`, 0},
		{`/tmp/neovide.sock`, 0},
		{``, 0},
		{`neovide_`, 0},
		{`neovide_12abc`, 12},
	}

	for _, test := range tests {
		if got := pidFromServer(test.server); got != test.want {
			t.Errorf("pidFromServer(%q) = %d, want %d", test.server, got, test.want)
		}
	}
}

func TestParseArgs(t *testing.T) {
	tests := []struct {
		name    string
		argv    []string
		want    launchArgs
		wantErr bool
	}{
		{
			name: "file",
			argv: []string{"neovide.exe", "file.txt"},
			want: launchArgs{neovide: "neovide.exe", args: []string{"file.txt"}},
		},
		{
			name: "no arguments",
			argv: []string{"neovide.exe"},
			want: launchArgs{neovide: "neovide.exe", args: []string{}},
		},
		{
			name: "cwd",
			argv: []string{"neovide.exe", "--cwd", `C:\proj`, "file.txt"},
			want: launchArgs{neovide: "neovide.exe", cwd: `C:\proj`, args: []string{"file.txt"}},
		},
		{
			name: "cwd only",
			argv: []string{"neovide.exe", "--cwd", `/home/me/proj`},
			want: launchArgs{neovide: "neovide.exe", cwd: `/home/me/proj`, args: []string{}},
		},
		{
			name:    "cwd without directory",
			argv:    []string{"neovide.exe", "--cwd"},
			wantErr: true,
		},
		{
			name:    "empty argv",
			argv:    []string{},
			wantErr: true,
		},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			got, err := parseArgs(test.argv)
			if test.wantErr {
				if err == nil {
					t.Fatal("expected an error")
				}
				return
			}
			if err != nil {
				t.Fatalf("parseArgs returned error: %v", err)
			}
			if got.neovide != test.want.neovide {
				t.Errorf("neovide = %q, want %q", got.neovide, test.want.neovide)
			}
			if got.cwd != test.want.cwd {
				t.Errorf("cwd = %q, want %q", got.cwd, test.want.cwd)
			}
			if !reflect.DeepEqual(got.args, test.want.args) {
				t.Errorf("args = %#v, want %#v", got.args, test.want.args)
			}
		})
	}
}
