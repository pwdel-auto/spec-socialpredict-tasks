#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_LIB_DIR="$(cd "$SCRIPT_DIR/../../lib" && pwd)"
# shellcheck source=../../lib/socialpredict_backend_common.sh
source "$SKILLS_LIB_DIR/socialpredict_backend_common.sh"

REPO_DIR="$(resolve_target_repo_dir "${1:-}")"
BACKEND_DIR="$(require_backend_dir "$REPO_DIR")"
BACKEND_DIR="$(cd "$BACKEND_DIR" && pwd)"
SPEC_PATH="$BACKEND_DIR/docs/openapi.yaml"

if [ ! -f "$SPEC_PATH" ]; then
  echo "Expected OpenAPI spec at $SPEC_PATH" >&2
  exit 1
fi

if [ ! -f "$BACKEND_DIR/go.mod" ]; then
  echo "Expected Go module at $BACKEND_DIR/go.mod" >&2
  exit 1
fi

TMP_ROOT="${TMPDIR:-/tmp}/socialpredict-kin-conformance"
mkdir -p "$TMP_ROOT"

GO_CACHE_DIR="$TMP_ROOT/gocache"
GO_MOD_CACHE_DIR="$TMP_ROOT/gomodcache"
mkdir -p "$GO_CACHE_DIR" "$GO_MOD_CACHE_DIR"

TMP_GO="$(mktemp "$TMP_ROOT/kin-conformance-XXXX.go")"
cleanup() {
  rm -f "$TMP_GO"
}
trap cleanup EXIT

cat >"$TMP_GO" <<'EOF'
package main

import (
	"context"
	"fmt"
	"os"
	"sort"
	"strings"

	"github.com/getkin/kin-openapi/openapi3"
)

func fail(format string, args ...any) {
	fmt.Fprintf(os.Stderr, format+"\n", args...)
	os.Exit(1)
}

func main() {
	if len(os.Args) != 2 {
		fail("usage: kin-conformance <spec-path>")
	}

	ctx := context.Background()
	loader := &openapi3.Loader{IsExternalRefsAllowed: true}
	doc, err := loader.LoadFromFile(os.Args[1])
	if err != nil {
		fail("load OpenAPI document: %v", err)
	}
	if err := doc.Validate(ctx); err != nil {
		fail("validate OpenAPI document: %v", err)
	}

	var problems []string
	operationCount := 0

	for path, pathItem := range doc.Paths.Map() {
		for method, operation := range pathItem.Operations() {
			operationCount++
			label := strings.ToUpper(method) + " " + path
			if operation.OperationID == "" {
				problems = append(problems, label+": missing operationId")
			}
			if operation.Responses == nil || operation.Responses.Len() == 0 {
				problems = append(problems, label+": missing responses")
				continue
			}
			for status, responseRef := range operation.Responses.Map() {
				if responseRef == nil || responseRef.Value == nil {
					problems = append(problems, label+": nil response for status "+status)
					continue
				}
				for mediaType, mediaRef := range responseRef.Value.Content {
					if mediaRef == nil {
						problems = append(problems, label+": nil media type "+mediaType+" for status "+status)
						continue
					}
					if mediaRef.Schema != nil && mediaRef.Schema.Value == nil && mediaRef.Schema.Ref == "" {
						problems = append(problems, label+": empty schema for "+status+" "+mediaType)
					}
				}
			}
		}
	}

	if len(problems) > 0 {
		sort.Strings(problems)
		for _, problem := range problems {
			fmt.Fprintln(os.Stderr, problem)
		}
		fail("kin-openapi conformance found %d issue(s)", len(problems))
	}

	fmt.Printf("PASS: kin-openapi loaded and validated %d operation(s)\n", operationCount)
}
EOF

echo "[1/2] Run existing backend OpenAPI validation test"
(
  cd "$BACKEND_DIR"
  GOCACHE="$GO_CACHE_DIR" GOMODCACHE="$GO_MOD_CACHE_DIR" go test ./... -run TestOpenAPISpecValidates -count=1
)

echo "[2/2] Run kin-openapi operation conformance checks"
(
  cd "$BACKEND_DIR"
  GOCACHE="$GO_CACHE_DIR" GOMODCACHE="$GO_MOD_CACHE_DIR" go run "$TMP_GO" "$SPEC_PATH"
)
