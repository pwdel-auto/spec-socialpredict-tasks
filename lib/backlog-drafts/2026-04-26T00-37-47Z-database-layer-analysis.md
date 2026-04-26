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

## FAQ Appendix

### What is the difference between the original production-note idea of `database/`, `repository/`, and `dal/` versus the current architecture direction?

The old production note treated the backend like a technical stack:

- `database/`: connection setup, transactions, health
- `repository/`: CRUD wrappers over models
- `dal/`: `Data Access Layer`, a facade over repositories and transactions

That makes "data access" the center of the architecture.

The current direction is different:

- runtime/bootstrap owns DB setup and startup workflows in `main.go` and `internal/app/runtime/db.go`
- the composition root wires the app in `internal/app/container.go`
- repositories are adapters at the edge, not the top-level architecture
- domain and use-case correctness matter more than inventing another generic DB layer

The important clarification is that the new direction does not preserve a central DAL under a different name. The concerns the older DAL wanted to gather are being decomposed more cleanly:

- runtime/bootstrap owns DB lifecycle and startup workflows
- repositories own translation at the persistence edge
- domain and application workflows own business behavior

### What does DAL stand for?

`DAL` stands for `Data Access Layer`.

In many codebases it means a generic facade over repositories, connections, and transaction handling. In this codebase it would likely become a god-object or service locator that hides ownership instead of clarifying it.

### Why is DAL a bad fit here?

Because it collapses several concerns into one generic bucket:

- runtime DB lifecycle
- transaction coordination
- repository access
- sometimes domain workflow orchestration

The real risks here are:

- unclear startup ownership
- unclear migration and seed ownership
- weak readiness behavior
- lingering ambient DB state via `SetDB` and `GetDB`
- lack of explicit transaction boundaries for accounting-sensitive workflows

A DAL would hide those issues instead of resolving them.

### What does "building a second architecture" mean?

It means introducing a new top-level `database/` plus `repository/` plus `dal/` world while the real application already uses:

- `internal/app/runtime`
- `internal/app/container`
- `internal/repository`
- `internal/domain`

That creates two competing patterns in one codebase. The codebase becomes harder to reason about because developers can no longer tell which structure is authoritative.

### What is an edge translator versus a CRUD facade?

An `edge translator` is a repository that sits at the boundary and translates persistence details into domain-friendly types and domain-shaped operations.

A `CRUD facade` is a generic wrapper that mostly offers:

- create
- read
- update
- delete

CRUD is not the same thing as "just using a database." It is a software abstraction shaped around generic create, read, update, and delete operations. The current direction wants edge translators, not CRUD facades, because SocialPredict is not a generic admin app. It has domain-specific workflows and correctness rules.

### What is the startup-ownership risk?

Right now every process behaves like both:

- an app replica
- a startup coordinator

Each instance in `main.go` currently:

- loads DB config
- opens the DB
- waits for DB ping
- runs migrations
- loads config
- seeds admin and homepage data
- starts serving

That means replica startup is not purely local and read-only. It includes shared-state mutation. That is risky in a high-availability deployment.

### What does "per-process startup ownership of DB bootstrap tasks" mean?

It means every process currently "owns" too much of startup:

- DB opening
- readiness waiting
- migration execution
- seeding

A cleaner ownership model would be:

- each app replica owns only its own pool and request serving
- one migration job or one elected leader owns schema changes
- one bootstrap or seed job owns one-time seed writes

### What are app replicas?

App replicas are multiple running instances of the same backend service behind a load balancer or orchestration platform.

If one instance dies, another can keep serving traffic. That is a basic HA pattern.

### What are stateless app replicas?

Stateless app replicas are interchangeable backend instances that hold no durable local truth.

They should be safe to start, stop, or replace at any time because durable state lives outside them, mainly in the database and other shared infrastructure.

What breaks statelessness is when every replica also tries to own one-off startup writes such as migrations and seed operations.

This is related to Kubernetes `Deployments` and `StatefulSets`, but it is not the same concept. Architectural statelessness is about durable ownership of truth, not only which Kubernetes controller is used.

### What is migration serialization?

Migration serialization means schema-changing startup work is performed by at most one writer at a time.

Other replicas should:

- wait
- observe completion
- or remain unready

until schema-changing work is finished.

### What are single-writer startup semantics?

This is a closely related idea: shared startup mutations should have one writer.

Examples:

- one process runs migrations
- one process performs one-time seed writes
- other replicas do not race to do the same shared writes

This is broader than migration ordering. It is about having one writer for shared startup mutations.

### Warning-only migration failure: should it be fatal?

For production traffic, usually yes. A safer posture is:

- fail startup
- or stay unready until schema compatibility is restored

Warning-only migration failure is sometimes tolerated in local development, but it is not a strong production HA posture.

### What is readiness versus liveness split?

`Liveness` asks:

- is the process running?

`Readiness` asks:

- should this instance receive traffic right now?

During DB impairment, a healthy architecture often reports:

- live = yes
- ready = no

That lets the platform stop routing traffic to the instance without necessarily killing the process.

This is a property of the application instance, not of the database by itself. The database can be impaired, and the application can still be live while not being ready.

### What is readiness behavior during DB impairment?

It means the service should make a deliberate choice about what happens when the DB is unavailable or degraded.

Examples:

- on startup, do not become ready until DB is usable
- after startup, if DB becomes unavailable, flip readiness to false
- keep liveness true if the process is still operational and can recover

Today the backend blocks startup on DB ping, but after startup `/health` always returns `200 ok`, which is too weak.

### What is runtime DB ownership?

Runtime DB ownership means one boundary owns:

- DB configuration
- opening the connection pool
- lifecycle management
- health semantics
- startup-time DB workflows

In this backend that ownership should live mainly under `internal/app/runtime` plus `main.go`, not in handlers and not in a generic helper layer.

Migration invocation belongs in that runtime/bootstrap ownership story as well, even if the migration implementation remains in the `migration/` package.

### Why is residual global DB fallback via `SetDB` and `GetDB` a problem?

Because it leaves ambient process-global DB state around.

That weakens explicit ownership and makes hidden coupling easier. Code can silently depend on shared global state instead of receiving its DB dependency intentionally.

### What does "compensation-based rather than atomic" mean?

`Atomic` means all required DB changes happen in one transaction:

- either all commit
- or all roll back

`Compensation-based` means the system performs step A, then step B, and if B fails it tries to undo A with another write.

That is weaker because the undo can also fail, or another request can interleave.

### Why is compensation-based behavior a problem here?

Because SocialPredict has accounting-sensitive flows.

If a bet flow:

- debits a balance
- then writes a bet
- then tries to refund on failure

that is weaker than one atomic transaction. It introduces more opportunities for inconsistency.

### Is this a separate concern from the database layer?

Yes, partially.

The database-layer note should answer questions like:

- who owns DB runtime
- who owns startup workflows
- where repositories live
- how readiness and migration ownership work

But the accounting-sensitive atomicity problem is narrower and more specific. It may deserve its own production note focused on:

- transactional integrity
- accounting consistency
- money-moving workflow boundaries

### What is a transaction boundary for accounting-sensitive flows?

It is the exact scope of work that must commit together or fail together.

For SocialPredict, the obvious candidates are:

- place bet
- sell position
- resolve market

Each of those should define one explicit unit of work for all required balance and state changes.

### How would we improve transaction boundaries specifically?

Likely by:

- introducing transaction-scoped repository binding or a narrow unit-of-work abstraction
- ensuring all required writes for one accounting-sensitive use case share one DB transaction
- avoiding read-then-write races where possible
- replacing compensate-after-the-fact patterns with atomic commit behavior

### What are unit-of-work policies for accounting-sensitive flows?

A `unit of work` policy answers:

- which use cases must be atomic
- which writes must share one transaction
- where the transaction starts
- where it ends
- what can be eventual versus what must be synchronous

For SocialPredict, accounting-sensitive units of work should be explicit and narrow rather than generic and framework-wide.

### What is concurrency control for balance updates?

It means protecting balance mutations so two overlapping requests cannot corrupt financial state.

Typical approaches include:

- row-level locks
- optimistic locking
- conditional atomic SQL updates

The right answer depends on the workflow, but the important part is to choose and document a policy.

This is not primarily about one database copying to another database. The immediate problem is protecting overlapping writes against the same primary system of record.

### What does "transaction vs compensation policy" mean?

It means deciding, use case by use case, whether a workflow must be:

- atomic in one DB transaction

or whether it is acceptable to:

- perform separate steps and compensate later

For accounting-sensitive workflows, the default should lean strongly toward atomic transactions unless there is a very strong reason otherwise.

Metrics and observability do not replace this requirement. If an accounting-sensitive write path can leave the system economically inconsistent, the right design goal is to prevent partial commit where practical, not merely to detect it later.

### What does "DB seam needs hardening" mean?

It means making the DB runtime boundary production-grade.

That includes:

- pool sizing
- connection lifetime
- idle connection management
- SSL ownership
- graceful startup and shutdown
- stronger readiness semantics

### What is pool sizing?

Pool sizing means configuring:

- maximum open DB connections
- maximum idle DB connections

so the application neither overwhelms Postgres nor starves itself under load.

### What is connection lifetime?

It means how long a DB connection is allowed to live before the app recycles it.

This helps avoid stale or unhealthy long-lived connections and gives better operational control.

### What does "DB pool, SSL, and connection lifecycle ownership in runtime bootstrap" mean?

It means the runtime/bootstrap layer should explicitly own:

- connection pool settings
- SSL/TLS mode
- connection lifetime and idle lifetime
- ping and readiness behavior
- eventual shutdown of the underlying `sql.DB`

These should not be scattered through handlers or pushed into app-policy config.

This does not require inventing a separate standalone "database service" inside the monolith. In the current backend, the right owner is the runtime/bootstrap layer.

### What are stronger readiness semantics?

It means readiness should reflect real service ability, not just process existence.

For example, readiness could depend on:

- can we reach the DB?
- is schema state acceptable?
- is the instance safe to serve DB-backed traffic?

### What are readiness semantics tied to actual DB condition?

It means readiness is derived from real DB state rather than a hard-coded "ok" response.

Examples:

- DB unreachable -> not ready
- schema mismatch -> not ready
- migration in progress -> possibly not ready
- connection pool exhausted beyond a threshold -> possibly degraded or not ready

### What is Redis exactly?

Redis is an in-memory data store commonly used for:

- caching
- session storage
- rate limiting
- distributed locking
- pub/sub
- queues and short-lived coordination state

### Is Redis a replacement for Postgres here?

No. Not for the core source of truth.

For SocialPredict, Postgres should remain the authoritative store for:

- balances
- bets
- markets
- resolutions

Redis is more appropriate as a supporting system, not the financial source of truth.

### Is Redis the same thing as connection pooling?

No.

These are different concerns:

- Postgres is the system of record
- connection pooling manages efficient DB connections
- Redis is a fast in-memory store for caching and coordination

### Do we need caching for high use?

Probably eventually, yes, but only after correctness and ownership are made explicit.

Good cache candidates:

- market list or search results
- leaderboard snapshots
- setup or config-derived public reads
- session or rate-limit state

Bad early cache candidates:

- balances
- core bet placement correctness
- payout correctness

Correctness comes before caching.

### Why the recommended sequence?

Because the order of risk matters:

1. harden runtime and startup ownership
2. fix accounting-sensitive transaction boundaries
3. improve readiness and telemetry
4. optimize and cache later

If you optimize first, you risk making an incorrect system faster instead of safer.

## Reading Material

This reading list is intentionally broad. It is meant to anchor the terminology and patterns discussed in this appendix: domain boundaries, repositories, unit of work, transactions, consistency, HA, replicas, health checks, caching, Redis, and runtime ownership.

### Core Architecture and Domain Design

- Eric Evans, *Domain-Driven Design: Tackling Complexity in the Heart of Software*.
  Foundational for bounded contexts, ubiquitous language, and keeping supporting technical concerns subordinate to the domain.

- Vaughn Vernon, *Implementing Domain-Driven Design*.
  Very useful for turning Evans-style design into repositories, aggregates, services, and practical boundaries.

- Vaughn Vernon, *Domain-Driven Design Distilled*.
  Shorter and faster to absorb than Evans if you want a lighter first pass.

- Robert C. Martin, *Clean Architecture: A Craftsman's Guide to Software Structure and Design*.
  Strong on dependency direction, boundaries, and why frameworks and databases should not become the center of the design.

- Martin Fowler, *Patterns of Enterprise Application Architecture*.
  Canonical source for `Repository`, `Unit of Work`, `Data Mapper`, and many of the patterns being discussed here.

- Neal Ford, Rebecca Parsons, and Patrick Kua, *Building Evolutionary Architectures*.
  Good for understanding how to evolve architecture in place without rewriting everything.

- Sam Newman, *Monolith to Microservices*.
  Useful here not because you should split now, but because it explains how to make a monolith extraction-ready through boundary clarity.

### Enterprise Application Patterns and Transaction Boundaries

- Martin Fowler, *Patterns of Enterprise Application Architecture*.
  The most directly relevant book for `Repository`, `Unit of Work`, `Service Layer`, and transaction-related boundary vocabulary.

- Philip A. Bernstein and Eric Newcomer, *Principles of Transaction Processing*.
  Strong background on transactions, recovery, consistency, and why atomicity matters.

- Theo Harder and Andreas Reuter, *Principles of Transaction-Oriented Database Recovery*.
  More academic, but excellent if you want the deeper theory behind atomicity and recovery.

- Gerhard Weikum and Gottfried Vossen, *Transactional Information Systems*.
  A major reference for transaction semantics, concurrency control, and recovery behavior.

- Chris Richardson, *Microservices Patterns*.
  Useful for understanding sagas and compensation, including why compensation is different from atomic transactions.
  Even though the system is currently a monolith, the transaction versus compensation discussion is directly relevant.

### Data Systems, Consistency, Replication, and Caching

- Martin Kleppmann, *Designing Data-Intensive Applications*.
  Probably the single best book for the terms raised here: replication, transactions, consistency, caching tradeoffs, durability, and correctness.

- Alex Petrov, *Database Internals*.
  Helpful if you want a deeper systems-level understanding of storage engines, replication, and durability tradeoffs.

- Pramod J. Sadalage and Martin Fowler, *NoSQL Distilled*.
  Useful as a lightweight way to understand when caches or alternate data stores help and what tradeoffs they bring.

- Luc Perkins, *Understanding Distributed Systems*.
  Clear practical explanations of replication, coordination, and failure behavior.

### Reliability, Availability, and Operational Safety

- Michael T. Nygard, *Release It!: Design and Deploy Production-Ready Software*.
  Excellent on stability patterns, operational hazards, startup behavior, backpressure, and production failure modes.

- Betsy Beyer, Chris Jones, Jennifer Petoff, and Niall Richard Murphy, *Site Reliability Engineering*.
  Strong for thinking about health, readiness, operability, and production behavior.

- Betsy Beyer, Niall Richard Murphy, David K. Rensin, Kent Kawahara, and Stephen Thorne, *The Site Reliability Workbook*.
  More hands-on companion to the SRE book, especially useful for operational readiness practices.

- Brendan Burns, Joe Beda, and Kelsey Hightower, *Kubernetes: Up and Running*.
  Especially useful for readiness and liveness semantics if you expect replica-based deployment orchestration.

- Liz Rice, *Container Security*.
  Not central to the DB questions, but useful if your HA deployment thinking moves toward containerized runtime ownership.

### PostgreSQL and Runtime Database Operations

- Regina O. Obe and Leo S. Hsu, *PostgreSQL: Up and Running*.
  A practical Postgres book that is useful for everyday operational understanding.

- Dimitri Fontaine, *Mastering PostgreSQL in Application Development*.
  Good for thinking about application-facing Postgres behavior, transactions, and practical DB usage.

- Ibrar Ahmed and Greg Sabino Mullane, *PostgreSQL 10 High Availability Cookbook*.
  Version-specific, but still useful conceptually for HA Postgres patterns, failover thinking, and operational posture.

- Simon Riggs, Gianni Ciolli, Gabriele Bartolini, and others, *PostgreSQL Administration Cookbook*.
  Useful for administration, health, and runtime operational practices.

### Redis and Caching

- Josiah L. Carlson, *Redis in Action*.
  The clearest single book for what Redis does in practice: caching, counters, queues, locking, and ephemeral operational data.

- Karl Seguin, *The Little Redis Book*.
  Short and approachable if you want a fast conceptual introduction before a larger Redis text.

- Salvatore Sanfilippo and other Redis contributors are best read through the Redis docs and design notes, but for books `Redis in Action` remains the strongest practical starting point.

### Refactoring and Architectural Evolution

- Martin Fowler, *Refactoring: Improving the Design of Existing Code*.
  Valuable because this codebase is being evolved in place, not rewritten.

- Michael Feathers, *Working Effectively with Legacy Code*.
  Excellent for thinking about safe incremental change in a mixed old/new codebase like this one.

- Neal Ford, Mark Richards, Pramod Sadalage, and Zhamak Dehghani, *Software Architecture: The Hard Parts*.
  Very relevant to tradeoffs around transactions, consistency, distributed coordination, and data ownership.

- Gregor Hohpe and Bobby Woolf, *Enterprise Integration Patterns*.
  More integration-focused, but useful if startup ownership, queues, or asynchronous workflows become part of the design later.

### Recommended Reading Order

If you want the shortest high-value path:

1. Martin Fowler, *Patterns of Enterprise Application Architecture*
2. Eric Evans, *Domain-Driven Design*
3. Martin Kleppmann, *Designing Data-Intensive Applications*
4. Michael T. Nygard, *Release It!*
5. Josiah L. Carlson, *Redis in Action*

If you want the best path for the exact issues in this backend:

1. Vaughn Vernon, *Implementing Domain-Driven Design*
2. Martin Fowler, *Patterns of Enterprise Application Architecture*
3. Martin Kleppmann, *Designing Data-Intensive Applications*
4. Michael T. Nygard, *Release It!*
5. Chris Richardson, *Microservices Patterns*
6. Regina O. Obe and Leo S. Hsu, *PostgreSQL: Up and Running*

### Pattern-to-Book Quick Map

- `Repository`, `Unit of Work`, `Data Mapper`:
  Martin Fowler, *Patterns of Enterprise Application Architecture*

- bounded contexts, domain boundaries, supporting subdomains:
  Eric Evans, *Domain-Driven Design*
  Vaughn Vernon, *Implementing Domain-Driven Design*

- dependency direction, boundaries, clean layering:
  Robert C. Martin, *Clean Architecture*

- transactions, consistency, replication:
  Martin Kleppmann, *Designing Data-Intensive Applications*
  Gerhard Weikum and Gottfried Vossen, *Transactional Information Systems*

- compensation versus atomic transactions:
  Chris Richardson, *Microservices Patterns*
  Martin Kleppmann, *Designing Data-Intensive Applications*

- production hardening, availability, failure modes:
  Michael T. Nygard, *Release It!*
  *Site Reliability Engineering*

- readiness and liveness in orchestrated deployments:
  *Kubernetes: Up and Running*
  *The Site Reliability Workbook*

- Redis and caching:
  Josiah L. Carlson, *Redis in Action*
  Karl Seguin, *The Little Redis Book*
