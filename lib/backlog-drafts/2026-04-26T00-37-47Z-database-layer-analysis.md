# Database Layer Analysis

Status: temporary review artifact, not canonical design state.

Created: `2026-04-26T00:37:47Z`

Scope:
- compare `lib/design/design-plan.json`
- compare `../socialpredict/README/PRODUCTION-NOTES/BACKEND/04-database-layer.md`
- ground conclusions in the live backend under `../socialpredict/backend`

## Inputs Reviewed

- `lib/design/design-plan.json`
- `../socialpredict/README/PRODUCTION-NOTES/BACKEND/04-database-layer.md`
- `../socialpredict/backend/main.go`
- `../socialpredict/backend/internal/app/runtime/db.go`
- `../socialpredict/backend/internal/app/container.go`
- `../socialpredict/backend/server/server.go`
- `../socialpredict/backend/migration/migrate.go`
- `../socialpredict/backend/seed/seed.go`
- `../socialpredict/backend/internal/repository/users/repository.go`
- `../socialpredict/backend/internal/repository/markets/repository.go`
- `../socialpredict/backend/internal/domain/bets/bet_support.go`
- `../socialpredict/backend/handlers/stats/statshandler.go`
- `../socialpredict/backend/handlers/admin/adduser.go`

## Consolidated Findings

1. The production note is stale at the framing level.
It still describes a greenfield database-layer program centered on `util/postgres.go`, new repository work, and a new `database/` stack, but the live backend already has:
- runtime DB bootstrap in `internal/app/runtime/db.go`
- a composition root in `internal/app/container.go`
- existing repositories in `internal/repository/*`
- a migration runner in `migration/migrate.go`
- startup DB ping logic in `seed/seed.go`

2. The note proposes the wrong abstraction shape for the current codebase.
Its proposed top-level `database/`, `repository/`, and `dal/` layout would duplicate the existing composition root and push dependency direction the wrong way by re-centering repository contracts on `models.*`.

3. The design plan is materially closer to the live code than the note.
It already treats DB init, migration invocation, readiness, and seed bootstrapping as runtime/bootstrap concerns, and it already rejects generic retry behavior on accounting-sensitive writes.

4. The biggest HA risk is startup ownership.
Every process currently opens DB, waits for readiness, runs migrations, seeds, and then starts serving. That is not a safe long-term posture for stateless replicas in a high-availability deployment.

5. The biggest correctness risk is transaction and concurrency behavior on money-moving flows.
Bet placement and sale are still compensation-based rather than atomic. Balance mutation and market-resolution side effects need an explicit transaction and concurrency policy.

6. The runtime DB seam still needs hardening.
The live runtime DB config covers host, user, password, DB name, port, `sslmode`, and timezone, but it does not yet own pool sizing, connection lifetime, or stronger readiness semantics.

7. There are still request-boundary DB leaks.
The codebase is not “done” with handler-level DB use. `stats` and `admin/adduser` still take raw `*gorm.DB`, so “remove direct GORM usage from handlers” is still a real migration goal, just not from a zero baseline.

## What The Three Design Agents Agreed On

- Rewrite `04-database-layer.md` as a current-state-first architecture note, not as a greenfield implementation checklist.
- Do not update `lib/design/design-plan.json` until the production note direction is reviewed and accepted.
- Keep the existing composition root and repository seams.
- Focus the next database-layer direction on:
  - startup ownership
  - migration and seed ownership
  - readiness versus liveness
  - runtime DB hardening
  - transactional accounting-sensitive flows
  - remaining handler-level DB leaks

## Agent-Specific Emphasis

### Designer 01

- The note should explicitly target a practical near-term HA posture:
  stateless app replicas over one primary Postgres with one migration/seed owner or equivalent locking.
- The design plan later needs explicit decisions on:
  migration serialization, `AutoMigrate` fallback policy, transaction versus compensation policy, runtime DB ownership, and readiness behavior during DB impairment.

### Designer 02

- The main risk is building a second architecture beside the one already in production.
- The note should not restart repository architecture from scratch.
- The right sequence is:
  harden the runtime seam, separate bootstrap duties from replica startup, introduce narrow transaction scope for accounting-sensitive flows, then add DB readiness and telemetry.

### Designer 03

- Dependency direction matters most.
- Repositories should remain edge translators, not generic CRUD façades over `models.*`.
- A DAL/service-locator layer would be a regression and should be rejected.

## Recommended Direction For The Next Note Revision

Rewrite `../socialpredict/README/PRODUCTION-NOTES/BACKEND/04-database-layer.md` around these sections:

1. Current state
- runtime DB bootstrap already exists
- repositories already exist
- migrations and readiness already exist
- remaining direct DB handler leaks still exist

2. Architectural problems that actually matter now
- per-process startup ownership of DB bootstrap tasks
- warning-only migration failure
- `AutoMigrate` fallback policy
- weak readiness/liveness split
- lack of explicit transaction boundary for accounting-sensitive flows
- residual global DB fallback via `SetDB` and `GetDB`

3. Target direction
- runtime/bootstrap owns DB connection lifecycle and readiness
- app replicas should not all own migrations and seeds
- repositories stay where they are and continue to own translation
- transaction scope is introduced narrowly for `place`, `sell`, and `resolve`
- direct handler DB access continues to shrink behind service/repository seams

4. Explicit non-goals
- no new top-level `database/`, `repository/`, or `dal/` subsystem
- no generic retry or circuit-breaker behavior around financial writes
- no premature read-replica, sharding, or service-extraction work
- no moving runtime DB config into `setup.yaml`

## Candidate Design-Plan Follow-Ups Later

If the production note is accepted first, the design plan likely needs later updates for:

- single-writer startup semantics for migrations and seeds
- explicit transactional unit-of-work policy for accounting-sensitive flows
- concurrency control for balance updates
- DB pool, SSL, and connection-lifecycle ownership in runtime bootstrap
- readiness semantics tied to actual DB condition
- adding `migration/**` and `seed/**` to the design-plan source context

## Concrete Code References

- Runtime bootstrap: `../socialpredict/backend/internal/app/runtime/db.go`
- Startup sequence: `../socialpredict/backend/main.go`
- Composition root: `../socialpredict/backend/internal/app/container.go`
- Migration runner: `../socialpredict/backend/migration/migrate.go`
- Readiness ping loop: `../socialpredict/backend/seed/seed.go`
- Money-flow compensation: `../socialpredict/backend/internal/domain/bets/bet_support.go`
- Remaining handler DB coupling:
  - `../socialpredict/backend/handlers/stats/statshandler.go`
  - `../socialpredict/backend/handlers/admin/adduser.go`

## Explicit Do-Not-Do List

- Do not create a parallel `database/` or `dal/` architecture.
- Do not redefine repository interfaces around `models.*`.
- Do not treat generic retry/deadlock-retry as acceptable for accounting-sensitive writes.
- Do not leave migrations and seeds as a per-replica startup responsibility.
- Do not treat `AutoMigrate` fallback as an acceptable long-term production path.

## Notes

- No files in the target repo were changed as part of this analysis.
- No design-plan changes were made.
- This file exists so the analysis can be reviewed, questioned, and refined before any canonical artifact is updated.
