#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${1:-../socialpredict}"
if [[ $# -ge 2 ]]; then
  PACKAGES=("${@:2}")
else
  PACKAGES=(./...)
fi

if ! command -v go >/dev/null 2>&1; then
  echo "Go is required but not installed." >&2
  exit 1
fi

BACKEND_DIR="$REPO_DIR/backend"
if [[ ! -d "$BACKEND_DIR" ]]; then
  echo "Expected backend directory at: $BACKEND_DIR" >&2
  exit 1
fi

echo "Running: (cd $BACKEND_DIR && go vet ${PACKAGES[*]})"
(cd "$BACKEND_DIR" && go vet "${PACKAGES[@]}")
echo "PASS: go vet completed without findings."
