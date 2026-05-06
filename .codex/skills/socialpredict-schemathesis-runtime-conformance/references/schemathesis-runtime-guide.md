# Schemathesis Runtime Conformance Guide

Run Schemathesis only after deterministic kin-openapi validation passes.

## Preconditions

- The local backend is built and running.
- `backend/docs/openapi.yaml` validates with kin-openapi.
- `SCHEMATHESIS_BASE_URL` or the second script argument points to the running backend.
- The `schemathesis` CLI is installed in the current environment. The current
  supported CLI form is `schemathesis run --url <base-url> <schema>`.

If the backend is not running, use `socialpredict-local-backend-runtime` to prepare a non-Docker backend base URL. Do not run Docker from this skill.

## Runtime Policy

- Treat 5xx responses as likely implementation bugs unless the endpoint requires unavailable local dependencies or setup data.
- Treat documented/actual status-code, content-type, and schema mismatches as contract drift.
- Prefer updating `backend/docs/openapi.yaml` to match implemented behavior unless code is clearly broken.
- Keep auth-heavy or stateful endpoints scoped when credentials or seed data are unavailable.
- Keep generated request volume below the backend rate limit so conformance
  failures are not polluted by unrelated `429 RATE_LIMITED` responses.
- Do not introduce new containers or broad environment refactors just to run exploratory testing.

## Bounded Runtime Commands

Use a single worker and throttle below the general limiter. The wrapper defaults
to these values:

```bash
SCHEMATHESIS_BASE_URL=http://localhost:8080 \
  .codex/skills/socialpredict-schemathesis-runtime-conformance/scripts/run_schemathesis_runtime_conformance.sh ../socialpredict
```

Equivalent direct CLI command:

```bash
schemathesis run \
  --url http://localhost:8080 \
  --workers 1 \
  --rate-limit 30/m \
  --max-examples 10 \
  --generation-database none \
  --request-timeout 10 \
  backend/docs/openapi.yaml
```

Run login separately because `/v0/login` has a stricter limiter:

```bash
schemathesis run \
  --url http://localhost:8080 \
  --include-path /v0/login \
  --workers 1 \
  --rate-limit 4/m \
  --max-examples 5 \
  --generation-database none \
  backend/docs/openapi.yaml
```

To use the wrapper for the stricter login pass, override the defaults:

```bash
SCHEMATHESIS_BASE_URL=http://localhost:8080 \
SCHEMATHESIS_INCLUDE_PATH=/v0/login \
SCHEMATHESIS_RATE_LIMIT=4/m \
SCHEMATHESIS_MAX_EXAMPLES=5 \
  .codex/skills/socialpredict-schemathesis-runtime-conformance/scripts/run_schemathesis_runtime_conformance.sh ../socialpredict
```

Use a fixed test client header when the goal is to test one client's limiter
behavior instead of rotating through generated client identities:

```bash
schemathesis run \
  --url http://localhost:8080 \
  --include-path /v0/login \
  --workers 1 \
  --rate-limit 4/m \
  --max-examples 5 \
  --generation-database none \
  -H 'X-Forwarded-For: 203.0.113.50' \
  backend/docs/openapi.yaml
```

Wrapper equivalent:

```bash
SCHEMATHESIS_BASE_URL=http://localhost:8080 \
SCHEMATHESIS_INCLUDE_PATH=/v0/login \
SCHEMATHESIS_RATE_LIMIT=4/m \
SCHEMATHESIS_MAX_EXAMPLES=5 \
SCHEMATHESIS_HEADER='X-Forwarded-For: 203.0.113.50' \
  .codex/skills/socialpredict-schemathesis-runtime-conformance/scripts/run_schemathesis_runtime_conformance.sh ../socialpredict
```

For broader API conformance, split runs by endpoint family instead of running
all operations at once. This keeps rate-limit effects interpretable:

```bash
schemathesis run \
  --url http://localhost:8080 \
  --include-path-regex '^/health|^/readyz' \
  --workers 1 \
  --max-examples 5 \
  backend/docs/openapi.yaml
```

```bash
schemathesis run \
  --url http://localhost:8080 \
  --include-path-regex '^/v0/markets' \
  --workers 1 \
  --rate-limit 30/m \
  --max-examples 5 \
  backend/docs/openapi.yaml
```

```bash
schemathesis run \
  --url http://localhost:8080 \
  --include-path /v0/login \
  --workers 1 \
  --rate-limit 4/m \
  --max-examples 5 \
  backend/docs/openapi.yaml
```

Wrapper endpoint-family examples:

```bash
SCHEMATHESIS_BASE_URL=http://localhost:8080 \
SCHEMATHESIS_INCLUDE_PATH_REGEX='^/health|^/readyz' \
SCHEMATHESIS_MAX_EXAMPLES=5 \
  .codex/skills/socialpredict-schemathesis-runtime-conformance/scripts/run_schemathesis_runtime_conformance.sh ../socialpredict
```

```bash
SCHEMATHESIS_BASE_URL=http://localhost:8080 \
SCHEMATHESIS_INCLUDE_PATH_REGEX='^/v0/markets' \
SCHEMATHESIS_RATE_LIMIT=30/m \
SCHEMATHESIS_MAX_EXAMPLES=5 \
  .codex/skills/socialpredict-schemathesis-runtime-conformance/scripts/run_schemathesis_runtime_conformance.sh ../socialpredict
```

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
