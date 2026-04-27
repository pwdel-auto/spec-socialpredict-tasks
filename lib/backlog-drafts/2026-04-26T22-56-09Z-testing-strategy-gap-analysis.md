# Testing Strategy Gap Analysis

Status: non-canonical backlog draft

Purpose: capture the current comparison between the live backend test surface, the old `07-testing-strategy.md` production note, and the active design plan before any rewrite of the testing note or any design-plan edits.

## Inputs Reviewed

- `../socialpredict/README/PRODUCTION-NOTES/BACKEND/07-testing-strategy.md`
- `lib/design/design-plan.json`
- `../socialpredict/.github/workflows/backend.yml`
- representative live tests and helpers under:
  - `../socialpredict/backend/openapi_test.go`
  - `../socialpredict/backend/server/server_contract_test.go`
  - `../socialpredict/backend/internal/app/runtime/db_test.go`
  - `../socialpredict/backend/migration/migrate_test.go`
  - `../socialpredict/backend/seed/integration_test.go`
  - `../socialpredict/backend/internal/domain/analytics/systemmetrics_integration_test.go`
  - `../socialpredict/backend/handlers/markets/handler_contract_test.go`
  - `../socialpredict/backend/models/modelstesting/modelstesting.go`

This analysis also incorporates the three design-agent lenses:

- `software-designer-01-evans-agent`
- `software-designer-02-fowler-agent`
- `software-designer-03-martin-agent`

## Live Backend Snapshot

The current backend test surface is much more substantial than the old note assumes.

- `94` Go test files
- `343` `Test*` functions
- `35` test files using `httptest`
- `34` test files using `modelstesting.NewFakeDB`
- CI already runs a smoke startup job plus `go test ./...` in `../socialpredict/.github/workflows/backend.yml`

The dominant pattern is package-local testing with fast in-process helpers, not a centralized testing platform.

Examples already present:

- OpenAPI validity and route/spec parity in `../socialpredict/backend/openapi_test.go`
- Swagger/OpenAPI and auth contract checks in `../socialpredict/backend/server/server_contract_test.go`
- runtime DB seam tests in `../socialpredict/backend/internal/app/runtime/db_test.go`
- migration registry/order/idempotency tests in `../socialpredict/backend/migration/migrate_test.go`
- seed integration coverage in `../socialpredict/backend/seed/integration_test.go`
- accounting-sensitive analytics invariants in `../socialpredict/backend/internal/domain/analytics/systemmetrics_integration_test.go`
- handler boundary/contract tests with doubles in `../socialpredict/backend/handlers/markets/handler_contract_test.go`
- shared SQLite-backed fake DB support in `../socialpredict/backend/models/modelstesting/modelstesting.go`

## Consolidated Findings

### 1. The old note is stale on baseline facts

The current `07-testing-strategy.md` still describes a greenfield testing buildout:

- “limited testing”
- no integration framework
- no API suite
- no performance suite

That no longer matches the live backend. The repo already has broad coverage across:

- handlers
- server wiring
- OpenAPI contract
- auth middleware
- security middleware
- repositories
- domain services
- migrations
- seed/bootstrap behavior
- setup/runtime seams

The main gap is not absence of tests. The main gap is that the note does not describe the real test architecture or align test priorities with the active modernization slice.

### 2. The old note proposes a second testing architecture

The old note proposes:

- a top-level `testing/` subsystem
- a shared `TestSuite`
- testcontainers-first infrastructure
- separate integration/API/performance trees
- coverage quotas and performance targets
- example routes like `/v1/markets`

That does not match the live backend or the design plan.

The current codebase already uses a different testing shape:

- tests live near the owning package
- handler tests use `httptest`
- repository and domain tests use focused fakes and shared helpers
- many integration-style checks already run against in-memory SQLite via `modelstesting.NewFakeDB`
- server/OpenAPI tests already guard contract truthfulness

All three design agents converged on the same concern: following the old note literally would create a parallel testing architecture instead of strengthening the existing one.

### 3. The live test surface is package-local and seam-oriented

The real testing shape today is closer to:

- unit and component tests near handlers, services, repositories, and runtime helpers
- contract tests at the HTTP/OpenAPI boundary
- a small number of integration-style tests for cross-boundary invariants
- CI that already exercises smoke startup and `go test ./...`

That shape is consistent with the current design direction:

- handlers remain request-boundary translators
- repositories remain edge translators
- runtime/bootstrap owns infrastructure seams
- contract tests protect OpenAPI and public route behavior

This means `07-testing-strategy.md` should describe testing as evidence that owned boundaries hold, not as a standalone platform program.

### 4. The real strategic gap is priority, not framework

The active design plan is centered on:

- runtime readiness and health semantics
- single-writer startup and migration discipline
- request-boundary failure/security convergence
- database runtime hardening
- accounting-sensitive transaction correctness
- API/auth contract alignment

The current testing note barely addresses those priorities.

From the three agents, the most important under-tested or weakly-tested areas for HA/fault-tolerant SocialPredict are:

- Postgres-specific transaction and locking behavior
- multi-replica startup implications
- single-writer migration and seed semantics
- DB-backed readiness behavior after startup
- panic recovery and middleware-owned failure shaping
- compensation-style money flows that still need atomic transaction boundaries

In other words: the next testing work should follow the modernization risks, not generic test-program maturity checklists.

### 5. SQLite-backed helpers are useful, but they are not the whole story

`modelstesting.NewFakeDB` gives the suite a fast default:

- in-memory SQLite
- migrations applied
- low setup cost

That is a strong baseline for fast package-local coverage.

But it also creates a blind spot:

- SQLite is not a full substitute for Postgres locking, isolation, or concurrency behavior
- tests that pass under the fake DB may still miss HA-sensitive behavior in the real database/runtime model

The agents were aligned here: keep the SQLite helpers as the default, but add a very small number of real-Postgres smoke/integration tests only where SQLite is a poor proxy.

### 6. The old note should be rewritten as a current-state-first testing note

The rewrite direction should match the newer production-note template:

- frontmatter
- update summary
- executive direction
- why this matters
- current code snapshot
- actual test mix
- what testing should own
- what this note should not own
- near-term sequencing
- open questions
- explicit do-not-do list

The core framing should become:

- SocialPredict already has a meaningful backend test base
- the next job is to make that test base more intentional around the active runtime, DB, security, auth, and API modernization waves
- testing should stay close to ownership boundaries
- new test infrastructure should be introduced only where concrete verification gaps justify it

## Design-Agent Lens Summary

### Evans

The note is behind the ubiquitous language of the current system. It still talks like the backend lacks a real testing story, when the real issue is that the test story is not yet described in the same language as the modernized seams: runtime, migrations, auth boundary, failure translation, repositories, and accounting correctness.

### Fowler

The right move is evolutionary:

- inventory the real test surface
- preserve the fast package-local defaults
- improve tests around the active modernization waves
- add only a narrow amount of heavier infrastructure where the existing style is insufficient

The wrong move is to build a large `testing/` subsystem first.

### Martin

Testing should reinforce dependency direction, not blur it. A shared `TestSuite` or top-level platform tree would tend to centralize DB, auth, transport, and runtime details into one harness and normalize transitional leaks. Tests should expose boundary violations and migration seams, not bless them as the permanent architecture.

## Recommended Rewrite Direction For 07-Testing-Strategy.md

Rewrite `07-testing-strategy.md` into a seam-oriented production note for the live backend.

It should explicitly document:

- the existing test mix:
  - package-local unit/component tests
  - handler/contract tests
  - OpenAPI/server contract tests
  - runtime/migration/security tests
  - a small number of integration-style invariant tests
- the existing shared helpers:
  - `modelstesting`
  - `setuptesting`
- the current CI baseline:
  - smoke startup
  - `go test ./...`
- the most important near-term test priorities:
  - runtime/readiness behavior
  - migration/startup-writer discipline
  - security and middleware failure semantics
  - accounting-sensitive transaction boundaries
  - API/auth contract convergence

It should also state clearly that the backend is not currently adopting:

- a top-level `testing/` platform
- testcontainers-by-default
- a broad API/performance/load-testing program
- coverage quotas as the main goal
- benchmark gating as part of the current modernization slice

## Suggested Near-Term Testing Focus

The three agents were strongly aligned on the next useful testing direction:

1. Keep fast package-local tests as the default posture.
2. Expand boundary-safe tests around runtime, failure, auth, DB, and API seams already being modernized.
3. Add a very small set of real-Postgres checks only for behaviors SQLite cannot model credibly.
4. Defer large test-platform ambitions until the runtime and DB ownership model is stable.

Concretely, the next high-value testing additions would likely focus on:

- readiness behavior tied to real DB condition
- startup behavior when migrations fail
- single-writer startup assumptions
- transaction correctness for place/sell/resolve flows
- middleware/public failure convergence
- proxy-sensitive rate-limiting behavior
- docs publishing behavior under proxied `/api/` deployment topology

## Explicit Deferrals

The draft note should defer or reject for this slice:

- top-level `backend/testing/` tree
- `TestSuite` base class as the default architecture
- testcontainers-first posture
- dedicated performance/load/stress suites
- coverage quotas and dashboard-first goals
- benchmark gating
- broad CI redesign
- generated mock/factory ecosystems as a prerequisite for progress

## Bottom Line

`07-testing-strategy.md` is not mainly wrong because SocialPredict lacks tests. It is wrong because it describes the wrong era of the codebase and points toward the wrong kind of next move.

The correct next direction is to rewrite it as a current-state-first testing note for a backend that already has meaningful coverage, then use that note to steer new tests toward the real HA/fault-tolerance seams identified in the design plan.
