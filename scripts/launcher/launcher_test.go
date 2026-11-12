package main

import "testing"

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
