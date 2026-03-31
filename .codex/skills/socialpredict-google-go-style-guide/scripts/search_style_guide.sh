#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
REFERENCE_FILE="${SKILL_DIR}/references/google-go-style-guide.md"

usage() {
  cat <<'EOF'
Usage:
  search_style_guide.sh [--context N] <regex>
  search_style_guide.sh --list-topics

Search the local Google Go Style Guide reference with a case-insensitive regex
and print nearby lines for quick context.
EOF
}

list_topics() {
  cat <<'EOF'
Suggested topics:
clarity
simplicity
least mechanism
concision
maintainability
consistency
formatting
MixedCaps
line length
naming
local consistency
commentary
interfaces
dependencies
EOF
}

context_lines=3

while [[ $# -gt 0 ]]; do
  case "$1" in
    --context)
      if [[ $# -lt 2 ]]; then
        echo "missing value for --context" >&2
        usage >&2
        exit 1
      fi
      context_lines="$2"
      shift 2
      ;;
    --list-topics)
      list_topics
      exit 0
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      break
      ;;
    -*)
      echo "unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
    *)
      break
      ;;
  esac
done

if [[ $# -lt 1 ]]; then
  usage >&2
  exit 1
fi

pattern="$*"

if [[ ! -f "${REFERENCE_FILE}" ]]; then
  echo "reference file not found: ${REFERENCE_FILE}" >&2
  exit 1
fi

echo "reference: ${REFERENCE_FILE}"
echo "pattern: ${pattern}"
echo "context: ${context_lines}"
echo

if command -v rg >/dev/null 2>&1; then
  if ! rg --line-number --ignore-case --context "${context_lines}" -- "${pattern}" "${REFERENCE_FILE}"; then
    echo "no matches" >&2
    exit 1
  fi
  exit 0
fi

if ! grep -Eni -C "${context_lines}" -- "${pattern}" "${REFERENCE_FILE}"; then
  echo "no matches" >&2
  exit 1
fi
