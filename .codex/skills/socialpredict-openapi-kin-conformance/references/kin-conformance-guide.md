# kin-openapi Conformance Guide

Use this skill before exploratory runtime testing.

## Source-of-Truth Order

1. `backend/server/server.go`
2. Relevant handlers under `backend/handlers/**`
3. DTOs, JSON tags, middleware-visible behavior, and tests
4. `backend/docs/openapi.yaml`

Prefer updating the spec to match code unless the implementation is clearly broken, unsafe, or inconsistent with existing tests.

## Deterministic Checks

- Load `backend/docs/openapi.yaml` with `github.com/getkin/kin-openapi/openapi3`.
- Run OpenAPI document validation.
- Confirm every operation has at least one documented response.
- Confirm response content schemas are parseable and referenced components resolve.
- For touched endpoints, compare documented status codes, content types, and response shapes to actual handler behavior.

## Request/Response Validation Policy

Use kin-openapi for focused request and response validation when fixtures are available or easy to construct. Keep fixtures small and tied to touched endpoints. Do not add broad generated fixture frameworks unless the task explicitly asks for them.

For runtime exploration, run Schemathesis after the kin-openapi checks pass.

## Reporting

Report:

- mismatched route, method, status code, content type, request body, response body, or error shape
- whether the fix changed spec, code, or tests
- the exact kin-openapi command and pass/fail result
- remaining drift classified as blocker, high, or follow-up
