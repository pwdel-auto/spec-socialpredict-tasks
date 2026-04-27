# Late Production Notes Priority Analysis

Status: non-canonical backlog draft

Purpose: capture a current-state-first re-ranking of the remaining backend production notes after `07-testing-strategy.md`, grounded in the live backend, the active design plan, and three design-agent reviews.

## Inputs Reviewed

- `../socialpredict/README/PRODUCTION-NOTES/BACKEND/08-performance-optimization.md`
- `../socialpredict/README/PRODUCTION-NOTES/BACKEND/09-deployment-infrastructure.md`
- `../socialpredict/README/PRODUCTION-NOTES/BACKEND/10-monitoring-alerting.md`
- `../socialpredict/README/PRODUCTION-NOTES/BACKEND/11-data-validation.md`
- `../socialpredict/README/PRODUCTION-NOTES/BACKEND/12-background-jobs.md`
- `../socialpredict/README/PRODUCTION-NOTES/BACKEND/13-database-caching.md`
- `../socialpredict/README/PRODUCTION-NOTES/BACKEND/plan.md`
- `lib/design/design-plan.json`
- representative live backend/runtime files:
  - `../socialpredict/backend/main.go`
  - `../socialpredict/backend/server/server.go`
  - `../socialpredict/backend/internal/app/runtime/db.go`
  - `../socialpredict/backend/security/security.go`
  - `../socialpredict/backend/security/validator.go`
  - `../socialpredict/backend/security/sanitizer.go`
  - `../socialpredict/backend/handlers/metrics/getsystemmetrics.go`
  - `../socialpredict/backend/internal/domain/analytics/system_metrics.go`
  - `../socialpredict/docker/backend/Dockerfile`
  - `../socialpredict/scripts/docker-compose-prod.yaml`
  - `../socialpredict/.github/workflows/backend.yml`
  - `../socialpredict/.github/workflows/docker.yml`
  - `../socialpredict/.github/workflows/deploy-to-staging.yml`
  - `../socialpredict/.github/workflows/deploy-to-production.yml`

This analysis incorporates:

- `software-designer-01-evans-agent`
- `software-designer-02-fowler-agent`
- `software-designer-03-martin-agent`

## Main Conclusion

The old ordering in [plan.md](/workspace/socialpredict/README/PRODUCTION-NOTES/BACKEND/plan.md) is now stale.

The remaining notes are not all peers.

They split into two broad categories:

- prerequisite runtime and boundary hardening that still matters before later optimization
- later optimization or platform expansion that should remain deferred or move into `FUTURE`

The strongest consensus across the three design agents was:

1. `09-deployment-infrastructure.md` should come earlier, but only after being heavily re-scoped to runtime/bootstrap reality.
2. `10-monitoring-alerting.md` should also come earlier, but only for minimal app-owned observability, not for a full Prometheus/Grafana/Alertmanager platform.
3. `11-data-validation.md` should stay active and likely comes before performance work, but only as consolidation of the existing `backend/security` validation and sanitization seam.
4. `08-performance-optimization.md`, `12-background-jobs.md`, and most of `13-database-caching.md` are later optimization or future platform work.

## Why The Old Ordering Is Wrong

The live backend still has prerequisite runtime and startup problems:

- every process still opens DB, waits for readiness, runs migrations, and seeds before serving in [main.go](/workspace/socialpredict/backend/main.go)
- `/health` is still only a hard-coded `ok` route in [server.go](/workspace/socialpredict/backend/server/server.go)
- runtime DB ownership is still transitional in [db.go](/workspace/socialpredict/backend/internal/app/runtime/db.go)
- the Dockerfile still has no healthcheck contract in [Dockerfile](/workspace/socialpredict/docker/backend/Dockerfile)
- prod compose still has no health/readiness orchestration in [docker-compose-prod.yaml](/workspace/socialpredict/scripts/docker-compose-prod.yaml)
- business metrics exist, but there is no infrastructure `/metrics` seam yet

That means deployment/runtime discipline, minimal observability, and request-boundary hardening are still earlier than caching, generic performance systems, or background job architecture.

## Re-Ranked Order

### 1. `09-deployment-infrastructure.md`

Priority: earlier, but only after rewrite and re-scope

What should stay active:

- graceful shutdown
- real liveness/readiness/startup semantics
- startup-writer discipline and rollout safety
- healthchecks for the actual runtime contract
- docs publishing path and ingress/runtime expectations
- secret/env/runtime alignment

What should move out:

- Kubernetes manifests
- Helm
- Terraform
- broad multi-replica orchestration assumptions
- network-policy/compliance-style platform work
- large CI/CD redesign ideas

Why earlier:

- HA rollout is unsafe while `/health` is fake and startup still mutates shared state per process
- deployment notes currently assume routes and probes that do not exist

### 2. `10-monitoring-alerting.md`

Priority: earlier, but only as minimal runtime observability

What should stay active:

- logger/runtime correlation ownership
- request correlation
- panic recovery observability
- readiness/liveness signal ownership
- a small operational metrics seam

What should move out:

- Prometheus platform rollout
- Alertmanager
- Grafana
- ELK/log aggregation
- dashboards and incident tooling as a broad platform

Why earlier:

- observability is prerequisite runtime safety, not just later ops polish
- but the current note is too platform-heavy for the backend’s present state

### 3. `11-data-validation.md`

Priority: earlier than performance/caching/jobs

What should stay active:

- consolidate request-boundary validation and sanitization
- reuse `backend/security`
- normalize failure behavior around validation
- remove duplicated or ad hoc handler checks

What should move out:

- new generic `validation/` subsystem
- new generic `sanitization/` subsystem
- `/v1/*` route-table rule registry
- DB-backed business-rule validator engine
- response-wide output-sanitization platform

Why earlier:

- validation and sanitization already exist in the live backend
- the real need is consistency and owned boundary use, not another platform

### 4. `08-performance-optimization.md`

Priority: later optimization

What should be pulled forward into existing work:

- DB pool/lifecycle tuning belongs under runtime DB ownership, not under a new `performance/` subsystem

What should stay later:

- query-optimizer subsystem
- runtime-created indexes
- caching layers
- compression as a broad platform topic
- profiling/perf programs

Why later:

- correctness, startup safety, observability, and boundary ownership still come first
- much of `08` overlaps with caching and even background-jobs ideas

### 5. `13-database-caching.md`

Priority: deferred, correctly so already

Current note direction is already aligned:

- correctness before caching
- Postgres remains source of truth
- Redis is only a possible future support system

Recommendation:

- keep it deferred
- optionally move it under `FUTURE` later if you want all optimization/platform topics grouped there

### 6. `12-background-jobs.md`

Priority: fully later / `FUTURE`

Why later:

- no live async platform exists today
- queue/worker/retry architecture would create a major new platform seam
- async jobs are dangerous before transaction boundaries, startup behavior, and idempotency rules are stable

What should move to `FUTURE`:

- basically the entire current note

## Recommended Post-`07` Priority

If these are rewritten in a better order, the next active order should be:

1. `09` re-scoped to runtime/bootstrap deployment reality
2. `10` re-scoped to minimal app-owned observability
3. `11` re-scoped to existing boundary validation/sanitization consolidation
4. `08` only after the above, and only as evidence-driven tuning
5. `13` remain deferred
6. `12` remain deferred / `FUTURE`

## What Should Move To `FUTURE`

Strong candidates:

- most of `09`: K8s, Helm, Terraform, large platform rollout
- most of `10`: Prometheus/Grafana/Alertmanager/ELK platform
- most of `08`: caching layers, profiling programs, compression platform, memory pools
- all of `12`: queue/worker/retry platform
- keep `13` deferred as-is, or explicitly relocate it into `FUTURE` if you want one place for later optimization work
- from `11`: any generic validation engine or DB-backed business-rule framework

## Boundary And Architecture Cautions

Across the remaining notes, the same anti-pattern keeps appearing:

- new top-level subsystems such as `performance/`, `monitoring/`, `validation/`, `sanitization/`, `jobs/`, and heavy middleware/platform trees

That is the wrong direction for the current backend.

The live architecture already has the main owners:

- `internal/app/runtime`
- `server`
- `security`
- `logger`
- `internal/domain/*`
- `internal/repository/*`

The right move is to extend and harden those seams, not build parallel platform trees beside them.

## Short Answer On Validation

Yes: your instinct is right.

`11-data-validation.md` should come before performance/caching/background jobs, but only after it is rewritten as:

- boundary hardening of the existing `backend/security` seam
- not a new validation framework
- not `/v1/*` rule tables
- not a second domain/business-rule engine

## Follow-Up Direction

The cleanest next editing sequence would be:

1. rewrite `09-deployment-infrastructure.md` into a current-state-first runtime/deployment note
2. rewrite `10-monitoring-alerting.md` into a minimal observability/runtime note and push the broader stack into `FUTURE`
3. rewrite `11-data-validation.md` into a current-state-first boundary-hardening note and defer the framework-heavy parts
4. leave `13` deferred
5. move `12` to `FUTURE`
6. rewrite `08` much later, after there is real performance evidence
