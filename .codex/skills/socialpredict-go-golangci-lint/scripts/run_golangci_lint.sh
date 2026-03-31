#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${1:-../socialpredict}"
if [[ $# -ge 2 ]]; then
  PACKAGES=("${@:2}")
else
  PACKAGES=(./...)
fi

if ! command -v golangci-lint >/dev/null 2>&1; then
  echo "golangci-lint is required but not installed." >&2
  echo "Install with: go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest" >&2
  exit 1
fi

BACKEND_DIR="$REPO_DIR/backend"
if [[ ! -d "$BACKEND_DIR" ]]; then
  echo "Expected backend directory at: $BACKEND_DIR" >&2
  exit 1
fi

echo "Running: (cd $BACKEND_DIR && golangci-lint run ${PACKAGES[*]})"
(cd "$BACKEND_DIR" && golangci-lint run "${PACKAGES[@]}")
echo "PASS: golangci-lint completed without findings."
