# Schemathesis Runtime Conformance Guide

Run Schemathesis only after deterministic kin-openapi validation passes.

## Preconditions

- The local backend is built and running.
- `backend/docs/openapi.yaml` validates with kin-openapi.
- `SCHEMATHESIS_BASE_URL` or the second script argument points to the running backend.
- The `schemathesis` CLI is installed in the current environment.

If the backend is not running, use `socialpredict-local-backend-runtime` to prepare a non-Docker backend base URL. Do not run Docker from this skill.

## Runtime Policy

- Treat 5xx responses as likely implementation bugs unless the endpoint requires unavailable local dependencies or setup data.
- Treat documented/actual status-code, content-type, and schema mismatches as contract drift.
- Prefer updating `backend/docs/openapi.yaml` to match implemented behavior unless code is clearly broken.
- Keep auth-heavy or stateful endpoints scoped when credentials or seed data are unavailable.
- Do not introduce new containers or broad environment refactors just to run exploratory testing.

## Triage Categories

- `blocker`: running API violates the documented contract for a supported local endpoint.
- `high`: spec and implementation disagree, but the endpoint requires known setup data or auth to fully reproduce.
- `follow-up`: Schemathesis coverage is blocked by missing local dependency, credentials, or seed data.

## Reporting

Report:

- base URL
- exact Schemathesis command
- pass/fail status
- failed endpoint/method/status/schema signal
- whether the fix belongs in spec, code, or test setup
- remaining blocker or follow-up
