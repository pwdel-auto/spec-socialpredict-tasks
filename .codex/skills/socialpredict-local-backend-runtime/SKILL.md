---
name: socialpredict-local-backend-runtime
description: Start or check a local non-Docker SocialPredict backend runtime for API conformance testing, using repo env defaults plus an existing or ephemeral local Postgres service.
---

# SocialPredict Local Backend Runtime

## When to Use

- Schemathesis or other runtime API tests need a running local backend.
- Docker is unavailable, unsafe, or intentionally avoided in this Codex environment.
- The task needs deterministic setup checks for backend env, Postgres reachability, and `/health`.

## Workflow

1. Read `references/local-runtime-guide.md`.
2. Run `scripts/start_local_backend_runtime.sh [repo-dir] check`.
3. If an external Postgres is already running, export DB env and run `start`.
4. If no DB is running and local Postgres binaries exist, run `start` to create an ephemeral non-Docker Postgres under `/tmp`.
5. Use the printed backend base URL as `SCHEMATHESIS_BASE_URL`.
6. Run `scripts/start_local_backend_runtime.sh [repo-dir] stop` when finished if this skill started processes.

## Commands

```bash
.codex/skills/socialpredict-local-backend-runtime/scripts/start_local_backend_runtime.sh ../socialpredict check
.codex/skills/socialpredict-local-backend-runtime/scripts/start_local_backend_runtime.sh ../socialpredict start
.codex/skills/socialpredict-local-backend-runtime/scripts/start_local_backend_runtime.sh ../socialpredict status
.codex/skills/socialpredict-local-backend-runtime/scripts/start_local_backend_runtime.sh ../socialpredict stop
```

## Working Rules

- Do not start Docker or Docker Compose from this skill.
- Do not write `.env` or `.env.dev`.
- Do not print database passwords, JWT signing keys, or other secrets.
- Prefer an already running local Postgres when env vars point to it.
- Use an ephemeral Postgres only when local Postgres binaries are available.
- Keep runtime state under `${TMPDIR:-/tmp}/socialpredict-local-backend-runtime`.

## Resources

- `references/local-runtime-guide.md`: runtime setup policy and environment mapping.
- `scripts/start_local_backend_runtime.sh`: deterministic check/start/status/stop wrapper.
