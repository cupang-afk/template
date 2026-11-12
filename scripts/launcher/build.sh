#!/bin/sh
# Build the Go launcher for the host OS/architecture.
set -eu
cd "$(dirname "$0")"

CGO_ENABLED=0 go build -trimpath -ldflags "-s -w" -o neovide-launcher .
echo "Build successful: $(pwd)/neovide-launcher"
