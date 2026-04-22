---
name: socialpredict-schemathesis-runtime-conformance
description: Run Schemathesis exploratory runtime testing against a compiled local SocialPredict backend after kin-openapi checks pass.
---

# SocialPredict Schemathesis Runtime Conformance

## When to Use

- Tasks that require verifying the running local backend against `backend/docs/openapi.yaml`.
- Follow-up runtime probing after deterministic kin-openapi validation passes.
- Exploratory checks for request/response mismatches, undocumented 5xx responses, or content-type/status-code drift.

## Workflow

1. Read `references/schemathesis-runtime-guide.md`.
2. Run `socialpredict-openapi-kin-conformance` first.
3. Use `socialpredict-local-backend-runtime` to check or start a non-Docker local backend when no backend is already running.
4. Set `SCHEMATHESIS_BASE_URL` to the local backend URL.
5. Run `scripts/run_schemathesis_runtime_conformance.sh [repo-dir] [base-url]`.
6. Classify failures as spec drift, implementation bug, unavailable local dependency/test data, or Schemathesis setup blocker.

## Command

Run from the TASK repo root:

```bash
SCHEMATHESIS_BASE_URL=http://127.0.0.1:8080 .codex/skills/socialpredict-schemathesis-runtime-conformance/scripts/run_schemathesis_runtime_conformance.sh ../socialpredict
```

Or pass the base URL explicitly:

```bash
.codex/skills/socialpredict-schemathesis-runtime-conformance/scripts/run_schemathesis_runtime_conformance.sh ../socialpredict http://127.0.0.1:8080
```

## Working Rules

- Do not add containers or deployment machinery just to run Schemathesis.
- Use the compiled local backend and existing local configuration.
- If backend runtime setup is needed, use `socialpredict-local-backend-runtime`; do not start Docker from this skill.
- Keep Schemathesis runs scoped when endpoint setup data or auth makes full exploration noisy.
- Report exact command, base URL, pass/fail result, and any blocked prerequisites.

## Resources

- `socialpredict-local-backend-runtime`: prepare or check the non-Docker local backend runtime before Schemathesis.
- `references/schemathesis-runtime-guide.md`: runtime conformance policy and triage rules.
- `scripts/run_schemathesis_runtime_conformance.sh`: Schemathesis CLI wrapper with clear dependency and base-URL checks.
