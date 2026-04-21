---
name: socialpredict-openapi-kin-conformance
description: Use kin-openapi for deterministic SocialPredict OpenAPI parsing, validation, and focused request/response conformance checks before runtime API probing.
---

# SocialPredict kin-openapi Conformance

## When to Use

- Tasks that must prove `backend/docs/openapi.yaml` is structurally valid.
- Tasks comparing implemented Go routes, handlers, DTOs, or error responses with the OpenAPI contract.
- Work that should run deterministic OpenAPI validation before Schemathesis or broader runtime testing.

## Workflow

1. Read `references/kin-conformance-guide.md`.
2. Inspect implemented routes and touched handlers before editing the spec.
3. Use `socialpredict-openapi-navigation` for targeted path, operation, schema, and `$ref` inspection.
4. Run `scripts/run_kin_openapi_conformance.sh [repo-dir]`.
5. Fix `backend/docs/openapi.yaml` to match implemented behavior unless code is clearly broken.
6. Re-run the kin-openapi check after each material spec or handler change.

## Command

Run from the TASK repo root and point at the TARGET repo root:

```bash
.codex/skills/socialpredict-openapi-kin-conformance/scripts/run_kin_openapi_conformance.sh ../socialpredict
```

## Working Rules

- Treat `backend/server/server.go`, handlers, DTOs, and tests as the implementation source of truth.
- Keep changes limited to touched paths, operations, schemas, and focused conformance tests/scripts.
- Do not normalize the API toward aspirational redesign notes.
- Record route, request, response, status-code, content-type, and error-shape mismatches.

## Resources

- `references/kin-conformance-guide.md`: deterministic conformance policy.
- `scripts/run_kin_openapi_conformance.sh`: kin-openapi-backed structural and operation sanity checks.
