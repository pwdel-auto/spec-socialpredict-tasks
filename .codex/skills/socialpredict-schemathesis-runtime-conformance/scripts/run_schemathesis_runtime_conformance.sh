#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_LIB_DIR="$(cd "$SCRIPT_DIR/../../lib" && pwd)"
# shellcheck source=../../lib/socialpredict_backend_common.sh
source "$SKILLS_LIB_DIR/socialpredict_backend_common.sh"

usage() {
  cat <<'EOF'
Usage: run_schemathesis_runtime_conformance.sh [repo-dir] [base-url]

The backend must already be running. Provide the base URL as the second
argument or through SCHEMATHESIS_BASE_URL.
EOF
}

REPO_DIR="$(resolve_target_repo_dir "${1:-}")"
BASE_URL="${2:-${SCHEMATHESIS_BASE_URL:-}}"
BACKEND_DIR="$(require_backend_dir "$REPO_DIR")"
SPEC_PATH="$BACKEND_DIR/docs/openapi.yaml"
SCHEMATHESIS_WORKERS="${SCHEMATHESIS_WORKERS:-1}"
SCHEMATHESIS_RATE_LIMIT="${SCHEMATHESIS_RATE_LIMIT:-30/m}"
SCHEMATHESIS_MAX_EXAMPLES="${SCHEMATHESIS_MAX_EXAMPLES:-10}"
SCHEMATHESIS_REQUEST_TIMEOUT="${SCHEMATHESIS_REQUEST_TIMEOUT:-10}"
SCHEMATHESIS_GENERATION_DATABASE="${SCHEMATHESIS_GENERATION_DATABASE:-none}"
SCHEMATHESIS_INCLUDE_PATH="${SCHEMATHESIS_INCLUDE_PATH:-}"
SCHEMATHESIS_INCLUDE_PATH_REGEX="${SCHEMATHESIS_INCLUDE_PATH_REGEX:-}"
SCHEMATHESIS_HEADER="${SCHEMATHESIS_HEADER:-}"

if [ -z "$BASE_URL" ]; then
  usage >&2
  exit 2
fi

if [ ! -f "$SPEC_PATH" ]; then
  echo "Expected OpenAPI spec at $SPEC_PATH" >&2
  exit 1
fi

if ! command -v schemathesis >/dev/null 2>&1; then
  echo "schemathesis CLI is required but not installed or not on PATH." >&2
  exit 127
fi

echo "[1/2] Confirm backend is ready at $BASE_URL"
if command -v curl >/dev/null 2>&1; then
  curl --fail --silent --show-error --max-time 5 "$BASE_URL/readyz" >/dev/null || {
    echo "Backend did not report ready at $BASE_URL/readyz" >&2
    exit 1
  }
else
  echo "curl is not available; skipping readiness preflight"
fi

echo "[2/2] Run Schemathesis against backend/docs/openapi.yaml"
if schemathesis --help 2>/dev/null | grep -Eq '(^|[[:space:]])run([[:space:]]|$)'; then
  run_args=(
    run
    --url "$BASE_URL"
    --workers "$SCHEMATHESIS_WORKERS"
    --rate-limit "$SCHEMATHESIS_RATE_LIMIT"
    --max-examples "$SCHEMATHESIS_MAX_EXAMPLES"
    --generation-database "$SCHEMATHESIS_GENERATION_DATABASE"
    --request-timeout "$SCHEMATHESIS_REQUEST_TIMEOUT"
  )
  if [ -n "$SCHEMATHESIS_INCLUDE_PATH" ]; then
    run_args+=(--include-path "$SCHEMATHESIS_INCLUDE_PATH")
  fi
  if [ -n "$SCHEMATHESIS_INCLUDE_PATH_REGEX" ]; then
    run_args+=(--include-path-regex "$SCHEMATHESIS_INCLUDE_PATH_REGEX")
  fi
  if [ -n "$SCHEMATHESIS_HEADER" ]; then
    run_args+=(-H "$SCHEMATHESIS_HEADER")
  fi
  run_args+=("$SPEC_PATH")
  schemathesis "${run_args[@]}"
else
  echo "Installed schemathesis CLI does not expose the expected 'run' command." >&2
  echo "Run 'schemathesis --help' and adapt the command for this installed version." >&2
  exit 2
fi
