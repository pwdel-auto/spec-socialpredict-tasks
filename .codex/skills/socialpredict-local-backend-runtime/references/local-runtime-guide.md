# Local Backend Runtime Guide

Use this skill to prepare a local backend base URL for runtime conformance tests.

## Source Files

- Sample environment: `../socialpredict/.env.example`
- Backend entrypoint: `../socialpredict/backend/main.go`
- DB config loader: `../socialpredict/backend/internal/app/runtime/db.go`
- Server port: `BACKEND_PORT`, default `8080`
- Readiness endpoint: `GET /readyz`
- Liveness endpoint: `GET /health`

## Environment Mapping

The Docker Compose env uses `DB_HOST=db` for container networking. For a backend started directly on the host/container shell, use `DB_HOST=127.0.0.1` unless the caller provided a different reachable host.

Default local values from `.env.example`:

- `BACKEND_PORT=8080`
- `DB_PORT=5432`
- `POSTGRES_USER=user`
- `POSTGRES_PASSWORD=password`
- `POSTGRES_DATABASE=socialpredict_db`

Do not print secrets. It is fine to report whether required env values are present.

## Non-Docker Policy

Do not run Docker from inside this Codex container. It may require privileged Docker-in-Docker or host socket access. This skill should use one of these paths instead:

- an already running Postgres reachable through env vars
- an ephemeral local Postgres started from installed `initdb`, `postgres`, `pg_isready`, and `createdb` binaries

If neither path is available, report the exact blocker and leave Schemathesis runtime testing blocked.

## Cleanup

Use the skill's `stop` command after runtime testing. It stops only PIDs recorded in the skill state directory.
