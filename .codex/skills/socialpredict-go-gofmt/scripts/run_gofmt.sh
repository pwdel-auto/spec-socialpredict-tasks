#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${1:-../socialpredict}"
MODE="${2:-check}"
if [[ $# -ge 3 ]]; then
  TARGETS=("${@:3}")
else
  TARGETS=(.)
fi

if ! command -v gofmt >/dev/null 2>&1; then
  echo "gofmt is required but not installed." >&2
  exit 1
fi

BACKEND_DIR="$REPO_DIR/backend"
if [[ ! -d "$BACKEND_DIR" ]]; then
  echo "Expected backend directory at: $BACKEND_DIR" >&2
  exit 1
fi

case "$MODE" in
  check)
    echo "Running: (cd $BACKEND_DIR && gofmt -l ${TARGETS[*]})"
    OUTPUT="$(cd "$BACKEND_DIR" && gofmt -l "${TARGETS[@]}")"
    if [[ -z "$OUTPUT" ]]; then
      echo "PASS: gofmt reports no formatting drift."
      exit 0
    fi
    printf '%s\n' "$OUTPUT"
    echo "FAIL: gofmt reported formatting drift." >&2
    exit 1
    ;;
  write)
    echo "Running: (cd $BACKEND_DIR && gofmt -l ${TARGETS[*]})"
    BEFORE="$(cd "$BACKEND_DIR" && gofmt -l "${TARGETS[@]}")"
    if [[ -z "$BEFORE" ]]; then
      echo "No files required formatting."
      exit 0
    fi
    echo "Running: (cd $BACKEND_DIR && gofmt -w ${TARGETS[*]})"
    (cd "$BACKEND_DIR" && gofmt -w "${TARGETS[@]}")
    printf '%s\n' "$BEFORE"
    ;;
  *)
    echo "Unsupported mode: $MODE. Use 'check' or 'write'." >&2
    exit 1
    ;;
esac
