# API Design Gap Analysis

Status: non-canonical backlog draft

Purpose: capture the current comparison between the live backend API surface, the old `06-api-design.md` production note, and the active design plan before any rewrite of the note or any design-plan edits.

## Inputs Reviewed

- `../socialpredict/README/PRODUCTION-NOTES/BACKEND/06-api-design.md`
- `lib/design/design-plan.json`
- `../socialpredict/backend/docs/openapi.yaml`
- `../socialpredict/backend/docs/API-ISSUES.md`
- `../socialpredict/backend/docs/README.md`
- `../socialpredict/backend/server/server.go`
- `../socialpredict/backend/openapi_test.go`
- representative handlers and auth/security seams under:
  - `../socialpredict/backend/handlers/**`
  - `../socialpredict/backend/internal/service/auth/**`
  - `../socialpredict/backend/security/**`

This analysis also incorporates the three design-agent lenses:

- `software-designer-01-evans-agent`
- `software-designer-02-fowler-agent`
- `software-designer-03-martin-agent`

## Consolidated Findings

### 1. The old note is stale on baseline facts

The current [06-api-design.md](/workspace/socialpredict/README/PRODUCTION-NOTES/BACKEND/06-api-design.md) still describes a greenfield API-standardization effort.

That no longer matches the live backend:

- the backend already has a canonical [openapi.yaml](/workspace/socialpredict/backend/docs/openapi.yaml)
- the server already serves `/openapi.yaml` and `/swagger/` from [server.go](/workspace/socialpredict/backend/server/server.go)
- route/spec parity and embedded-spec checks already exist in [openapi_test.go](/workspace/socialpredict/backend/openapi_test.go)
- the repo already has an explicit deferred-follow-ups file in [API-ISSUES.md](/workspace/socialpredict/backend/docs/API-ISSUES.md)

The old note says:

- there is no OpenAPI or Swagger specification
- there should be a generated Swagger pipeline
- the API still needs a fresh standards layer

Those statements are now wrong.

### 2. The old note proposes a second architecture

The old note proposes a new top-level `api/` platform with:

- `standards.go`
- `versioning.go`
- `swagger.go`
- response-format middleware
- content negotiation
- pagination/filtering utilities
- generated clients

That would sit beside the live architecture instead of clarifying it.

The current backend already has the real API boundary pieces:

- route wiring in [server.go](/workspace/socialpredict/backend/server/server.go)
- shared envelope helpers in [envelope.go](/workspace/socialpredict/backend/handlers/envelope.go)
- auth helpers in [internal/service/auth](/workspace/socialpredict/backend/internal/service/auth)
- security middleware in [security](/workspace/socialpredict/backend/security)
- the contract document in [openapi.yaml](/workspace/socialpredict/backend/docs/openapi.yaml)

The current design plan already treats API cleanup as a later contract-alignment wave, not as a new platform build.

### 3. The live contract is mixed, but in a specific, already-documented way

The live API surface is not “missing standards.” It is mid-migration.

Current response families:

- shared envelope routes using `{ "ok": true, "result": ... }` and `{ "ok": false, "reason": ... }`
- raw JSON DTO routes
- middleware-generated `text/plain` `429` responses
- infra/documentation routes with non-JSON transport:
  - `/health`
  - `/openapi.yaml`
  - `/swagger/*`

Examples:

- shared envelope helpers: [envelope.go](/workspace/socialpredict/backend/handlers/envelope.go)
- mixed auth and profile/bets routes already using envelopes:
  - [loggin.go](/workspace/socialpredict/backend/internal/service/auth/loggin.go)
  - [buypositionhandler.go](/workspace/socialpredict/backend/handlers/bets/buying/buypositionhandler.go)
  - [sellpositionhandler.go](/workspace/socialpredict/backend/handlers/bets/selling/sellpositionhandler.go)
  - [privateuser.go](/workspace/socialpredict/backend/handlers/users/privateuser/privateuser.go)
- legacy/plain-text public routes still exist:
  - [publicuser.go](/workspace/socialpredict/backend/handlers/users/publicuser.go)
  - [portfolio.go](/workspace/socialpredict/backend/handlers/users/publicuser/portfolio.go)
  - [financial.go](/workspace/socialpredict/backend/handlers/users/financial.go)
  - [usercredit.go](/workspace/socialpredict/backend/handlers/users/credit/usercredit.go)
- middleware `429` is still plain text from [ratelimit.go](/workspace/socialpredict/backend/security/ratelimit.go)

The spec already reflects this mixed state through:

- `ReasonResponse`
- `PlainTextErrorResponse`

in [openapi.yaml](/workspace/socialpredict/backend/docs/openapi.yaml).

### 4. The real next problem is route-family convergence, not universal wrapping

The old note assumes the next move is a universal response wrapper plus rewriting middleware that captures and reformats handler output.

That is the wrong next move.

The actual next problem is:

- make the mixed route families explicit
- shrink the mixed state family by family
- keep OpenAPI truthful during the migration
- converge middleware and handler failures deliberately

The live backend already has a bounded public failure vocabulary in [envelope.go](/workspace/socialpredict/backend/handlers/envelope.go), and the plan already treats `PlainTextErrorResponse` as migration state instead of target state.

### 5. Versioning reality is simple

The live API versioning posture is:

- `/v0/*` for application routes
- unversioned infra routes such as `/health`, `/openapi.yaml`, and `/swagger/*`

There is no live:

- version manager
- header-based version selection
- `/v1` or `/v2`
- deprecation/sunset manager

If `06-api-design.md` is rewritten, it should document the current truth first and treat broader versioning policy as a later decision, not as an active implementation plan.

### 6. Pagination, search, and filtering are family-specific today

The old note proposes a universal `page/per_page/sort/order/meta/links` design.

The live contract is different:

- list routes use `limit` and `offset`
- markets use `status` and `created_by`
- search uses canonical `query` plus legacy `q`

See:

- [openapi.yaml](/workspace/socialpredict/backend/docs/openapi.yaml)
- [listmarkets.go](/workspace/socialpredict/backend/handlers/markets/listmarkets.go)
- [searchmarkets.go](/workspace/socialpredict/backend/handlers/markets/searchmarkets.go)

This does not mean the current API is ideal. It means any rewrite should document the real parameter families and only later decide whether there is enough value to justify broader normalization.

### 7. Auth semantics are already specific

The old note is too generic about auth.

The live backend already has a precise `mustChangePassword` policy:

- login returns a bearer token plus `mustChangePassword`
- most authenticated actions enforce password-change gating
- `POST /v0/changepassword` intentionally remains usable

Grounding:

- [loggin.go](/workspace/socialpredict/backend/internal/service/auth/loggin.go)
- [auth.go](/workspace/socialpredict/backend/internal/service/auth/auth.go)
- [changepassword.go](/workspace/socialpredict/backend/handlers/users/changepassword.go)
- [server_contract_test.go](/workspace/socialpredict/backend/server/server_contract_test.go)
- [API-ISSUES.md](/workspace/socialpredict/backend/docs/API-ISSUES.md)

That should be documented as a current contract rule, not folded into a broad token/platform redesign.

### 8. There is still real API drift, but it is bounded

The live API is not fully consistent yet.

Real gaps still present:

- `429` is still plain text from middleware
- global `405` behavior is still router-owned rather than application-owned
- some public user and reporting routes still use raw/plain-text behavior
- `internal/service/auth.HTTPError` still leaks transport-shaped policy inward
- route naming is mixed between resource paths, action paths, and legacy aliases

But the right description is:

- route/spec drift is largely under control
- route-family behavior is still mixed
- the next move is convergence and documentation, not reinvention

## Design-Agent Lens Summary

### Evans

API design should be treated as an existing boundary and contract-language problem, not as a platform-construction effort. The note should inventory the real route families, response families, auth semantics, and public language already in service.

### Fowler

The right move is evolutionary migration:

- document current source-of-truth order
- document mixed response families honestly
- make route-family migration explicit
- defer version-platform, codegen, and wrapper-platform work

### Martin

The old `api/` proposal would push presentation concerns into a new framework layer and make dependency direction worse. HTTP contract shaping belongs at the edge. A generic `API service` domain or response-rewriting middleware would be a clean-architecture regression.

## Recommended Rewrite Direction For 06-api-design.md

Rewrite `06-api-design.md` into the same current-state-first template used by the newer backend notes.

It should become something closer to:

- frontmatter
- update summary
- executive direction
- why this matters
- current code snapshot
- what API design should own
- what it should not own
- near-term sequencing
- open questions

Core framing:

- API design is now contract governance and route-family convergence for a live monolith
- OpenAPI already exists and should describe live behavior, not aspirations
- the source of truth remains:
  1. route wiring
  2. touched handlers/DTOs
  3. `openapi.yaml`
  4. deferred follow-up docs

The rewritten note should explicitly describe:

- current route families by tag and purpose
- current response families
- current failure families
- current versioning truth: `/v0` only
- current pagination/filter/search truth
- current `mustChangePassword` behavior
- which route families remain legacy

## Suggested Rewrite Topics

The rewritten note should say:

- do not build a new `api/` subsystem
- do not add universal response-rewriting middleware
- do not add HATEOAS, XML, content negotiation, or generator-first workflow
- do not claim universal REST or universal envelope consistency yet

It should instead drive:

- route-family migration matrix
- contract parity with `openapi.yaml`
- canonical parameter naming within current families
- explicit alias/deprecation notes for legacy routes
- explicit documentation of middleware-generated failures
- bounded cleanup of auth transport leakage

## Specific Questions Raised During Review

### Do we want an API “service” domain?

No.

API is not a business domain in this backend. The useful concept is the design plan’s API and Auth Contract Boundary, not a new “API service” layer.

### Do we want a `standards.go`?

Not as a central abstraction bucket.

A small helper surface is fine when it stays adapter-owned, like [envelope.go](/workspace/socialpredict/backend/handlers/envelope.go). A generic standards bucket would likely become a second architecture and policy dump.

### Do we want HATEOAS?

Not in the active slice.

Nothing in the live code or design plan points to a client-discovery problem that HATEOAS would solve. For this monolith, it would add transport complexity without addressing the real current defect, which is mixed route-family behavior.

### Are we fully RESTful?

No, and the repo already knows that.

The live route surface mixes:

- resource routes
- action routes
- legacy aliases
- service-shaped paths

Examples include:

- `/v0/bet`
- `/v0/sell`
- `/v0/changepassword`
- `/v0/profilechange/*`
- `/v0/marketprojection/*`
- `/v0/markets/active|closed|resolved`

That should be documented honestly and treated as a deferred route-reorganization problem, not rewritten casually in the current note.

### Are we using proper HTTP status codes?

Partly yes, partly mixed.

The API already uses useful distinctions such as:

- `201`
- `409`
- `422`

in several route families, but it also still has:

- plain-text middleware `429`
- router-level `405`
- some legacy plain-text handler failures

So the answer is not “start status-code design from scratch.” It is “document the current families and continue converging them.”

### Do we have standardized pagination?

No universal standard yet.

Current live standard is local to route families:

- `limit`
- `offset`
- `status`
- `created_by`
- `query`
- legacy `q`

### Do we have a versioning standard?

Only the current operational one:

- `/v0` application namespace
- unversioned infra routes

There is no documented sunset or parallel version-management policy yet.

### Should we add a Swagger/OpenAPI generator?

Not as the next move.

The backend already has:

- a hand-maintained [openapi.yaml](/workspace/socialpredict/backend/docs/openapi.yaml)
- embedded Swagger UI
- route/spec parity tests

The useful next step is contract accuracy and route-family migration discipline, not generator-first ownership.

## Suggested Active vs Deferred Split

### Active

- truthful documentation of live route and response families
- route-family migration matrix
- auth contract cleanup and `mustChangePassword` clarity
- boundary-failure convergence
- OpenAPI parity with code

### Deferred

- token redesign
- public route reorganization
- bets-to-trades rename
- header-based versioning
- `/v1` rollout and sunsets
- universal response wrapper
- HATEOAS
- XML/content negotiation
- generated client trees
- API platform package tree

## HA and Fault-Tolerance Cautions

The API note should not overclaim HA maturity.

Current operational cautions still visible at the API boundary:

- `/health` is only a simple liveness signal, not readiness
- rate limiting is in-process and not replica-consistent
- forwarded-header trust is still deployment-sensitive
- JWT key handling is still read ad hoc in auth today
- boundary failure behavior is still split across middleware, router, and handlers

For a high-availability SocialPredict backend, the note should keep API cleanup tied to:

- deterministic request behavior
- explicit boundary ownership
- truthful contract documentation
- route-family convergence

not to speculative API-platform expansion.
