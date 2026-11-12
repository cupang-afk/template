//go:build !windows && !linux && !darwin

package main

// Platforms without a supported window API can still reuse the running
// instance; they just cannot raise its window.
func focusInstance(string) {}

func focusNewInstance(int) {}
