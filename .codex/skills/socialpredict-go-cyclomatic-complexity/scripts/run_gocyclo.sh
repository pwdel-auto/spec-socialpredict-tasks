#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${1:-../socialpredict}"
OVER_THRESHOLD="${2:-4}"
if [[ $# -ge 3 ]]; then
  TARGETS=("${@:3}")
else
  TARGETS=(.)
fi

if ! [[ "$OVER_THRESHOLD" =~ ^[0-9]+$ ]]; then
  echo "Expected numeric gocyclo -over threshold, got: $OVER_THRESHOLD" >&2
  exit 1
fi

if ! command -v gocyclo >/dev/null 2>&1; then
  echo "gocyclo is required but not installed." >&2
  echo "Install with: go install github.com/fzipp/gocyclo/cmd/gocyclo@latest" >&2
  exit 1
fi

BACKEND_DIR="$REPO_DIR/backend"
if [[ ! -d "$BACKEND_DIR" ]]; then
  echo "Expected backend directory at: $BACKEND_DIR" >&2
  exit 1
fi

echo "Running: (cd $BACKEND_DIR && gocyclo -over $OVER_THRESHOLD ${TARGETS[*]})"
OUTPUT="$(cd "$BACKEND_DIR" && gocyclo -over "$OVER_THRESHOLD" "${TARGETS[@]}")"

if [[ -z "$OUTPUT" ]]; then
  echo "No functions exceeded gocyclo -over $OVER_THRESHOLD."
  exit 0
fi

printf '%s\n' "$OUTPUT"
