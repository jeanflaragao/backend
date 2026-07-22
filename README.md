<div align="center">

# Backend

**Backend Engineering Handbook for the betting-operations platform.**

[![CI](https://github.com/jeanflaragao/backend/actions/workflows/ci.yml/badge.svg)](https://github.com/jeanflaragao/backend/actions/workflows/ci.yml)
[![Ruby](https://img.shields.io/badge/ruby-3.2-CC342D?logo=ruby&logoColor=white)](Dockerfile)
[![Rails](https://img.shields.io/badge/rails-8.0.5-CC0000?logo=rubyonrails&logoColor=white)](Gemfile.lock)
[![PostgreSQL](https://img.shields.io/badge/postgresql-16-4169E1?logo=postgresql&logoColor=white)](../infra/compose/docker-compose.yml)
[![Coverage](https://img.shields.io/badge/coverage-not--configured-lightgrey)](#testing-conventions)

</div>

> [!IMPORTANT]
> Bookmaker account management (auth, CRUD, authorization, filtering/search/sort, serialization) is implemented and covered by the test suite — see [Current Capabilities](#current-capabilities) for exactly what exists, and the root [Roadmap](../README.md#roadmap) for what's planned (the financial engine: accounts, ledger, bankroll, reconciliation). **CI is scaffolded but currently disabled** (`.github/workflows/ci.yml` is commented out) — it is not yet a merge gate; run `bin/rubocop`, `bin/brakeman`, and `bundle exec rspec` locally. This handbook captures both: the system as it exists today, and the engineering standards used to evolve it safely.

Treat this file as the backend team's **Engineering Handbook**. A new engineer should be able to read it and understand how we build software in this repository: architecture direction, coding conventions, testing philosophy, performance posture, security practices, and review expectations. For conceptual design (diagrams, rationale, long-form architecture), see [docs/architecture/backend.md](../docs/architecture/backend.md).

## Table of Contents

- [How to Use This Handbook](#how-to-use-this-handbook)
- [Current Capabilities](#current-capabilities)
- [Technology Stack](#technology-stack)
- [Project Structure](#project-structure)
- [Architecture Philosophy](#architecture-philosophy)
- [Engineering Principles](#engineering-principles)
- [Guiding Principles](#guiding-principles)
- [Request Lifecycle](#request-lifecycle)
- [Error Handling Strategy](#error-handling-strategy)
- [Service Object Guidelines](#service-object-guidelines)
- [Query Object Guidelines](#query-object-guidelines)
- [Coding Standards](#coding-standards)
- [Local Development](#local-development)
- [Testing Conventions](#testing-conventions)
- [Naming Conventions](#naming-conventions)
- [Performance Guidelines](#performance-guidelines)
- [Security Practices](#security-practices)
- [Code Review Checklist](#code-review-checklist)
- [Linting & Security](#linting--security)

## How to Use This Handbook

Use this document in two ways:

- **As an onboarding map.** Start at [Current Capabilities](#current-capabilities) and [Project Structure](#project-structure) to understand what exists today.
- **As an engineering contract.** Use the standards sections (lifecycle, services, queries, testing, naming, performance, security, and reviews) when proposing, implementing, and reviewing changes.

When a decision conflicts with these conventions, document the trade-off in an ADR under [docs/adr/README.md](../docs/adr/README.md).

## Current Capabilities

Everything listed here exists in the codebase today. Nothing in this section is aspirational — planned work lives in the [Roadmap](../README.md#roadmap) instead.

**Application**
- Ruby on Rails 8.0.5 configured in API-only mode (`config.api_only = true`) — no view layer, no unnecessary middleware.
- Health-check endpoint (`GET /up`) suitable for load balancer / uptime monitoring integration.
- JWT authentication (`POST /api/v1/login`, `Jwt::Encoder`/`Jwt::Decoder`, the `Authenticatable` controller concern) — see [docs/architecture/backend.md](../docs/architecture/backend.md).
- Bookmaker account management (`GET/POST /api/v1/bookmakers`, `GET /api/v1/bookmakers/:id`) — create, list, and show, owned per user. Update and delete are not shipped yet (delete is in progress — see [Roadmap](../README.md#roadmap)).
- Authorization via Pundit policies (`BookmakerPolicy`), scoping index results to the authenticated user's own records.
- Query objects for filtering, search, and sort composition (`Bookmakers::IndexQuery` → `FilterQuery` → `SearchQuery` → `SortQuery`) plus pagination via Pagy.
- JSON serialization via Alba (`BookmakerSerializer`).
- Encrypted credentials via Rails' built-in credentials store (`config/credentials.yml.enc`), keeping secrets out of source control.
- Database-backed adapters configured for cache, background jobs, and Action Cable (Solid Cache, Solid Queue, Solid Cable) — the Rails 8 default of avoiding a Redis dependency for these concerns.
- One-command environment bootstrap (`bin/setup`) and server start (`bin/dev`).

**Testing & Quality Tooling**
- RSpec + FactoryBot test suite (request specs, model specs, policy specs, service specs) — see [Testing Conventions](#testing-conventions).
- RuboCop (Rails Omakase + `rubocop-performance` + `rubocop-rspec`) and Brakeman available via `bin/rubocop` / `bin/brakeman`.
- A GitHub Actions workflow exists (`.github/workflows/ci.yml`, security scan + lint + test) but is **currently disabled** (commented out) — it is not yet enforced on push/PR. Re-enabling it is tracked in the [Roadmap](../README.md#roadmap).
- Dependabot configured for both `bundler` and `github-actions` ecosystems, checked daily.
- Kamal deployment configuration scaffolded (`config/deploy.yml`, `.kamal/`) for containerized, zero-downtime deploys, fronted by Thruster for asset caching/compression.

For the target architecture this is being built toward — the financial engine's services, additional policies, and query objects — see [docs/architecture/backend.md](../docs/architecture/backend.md).

## Technology Stack

### Application

| Technology | Version | Purpose | Why |
|---|---|---|---|
| Ruby | 3.2 (pinned in `Dockerfile`) | Language runtime | Matches Rails 8's supported baseline. |
| Ruby on Rails | 8.0.5 | API-only application framework (`config.api_only = true`) | API-only strips the view layer this project doesn't need, keeping the surface area limited to the JSON contract. |
| PostgreSQL | 16 | System of record — primary relational datastore | Strong transactional guarantees, which an append-only ledger design depends on more than horizontal read scale at this stage. |
| Puma | ≥ 5.0 | Application server | Rails' default; no reason to deviate yet. |
| Solid Queue | Rails 8 default | Database-backed background job adapter | Avoids running Redis for jobs that don't yet need sub-millisecond latency — one fewer moving part locally and in staging. |
| Solid Cache | Rails 8 default | Database-backed `Rails.cache` adapter | Same rationale as Solid Queue. |
| Solid Cable | Rails 8 default | Database-backed Action Cable adapter | Configured by default; unused until a real-time feature (e.g. live notifications) needs it. |
| Bootsnap | latest | Boot-time caching for faster startup | Standard Rails optimization. |
| JWT (`jwt`) | latest | Stateless authentication tokens | Simple bearer-token auth suited to an API-only backend with no server-side session store. |
| Pundit | latest | Authorization policies | Explicit, testable policy objects per resource rather than authorization logic embedded in controllers/models. |
| Pagy | ~> 9.1 | Pagination | Minimal-overhead pagination without loading unnecessary gem weight for a concern this narrow. |
| Alba | latest | JSON serialization | Fast, explicit serializers with straightforward attribute remapping (e.g. exposing `website` as `homepage`). |

### Testing

| Tool | Role | Status |
|---|---|---|
| RSpec + FactoryBot | Primary testing stack | Active |
| Request specs | HTTP-boundary contract testing | Active — the default test type for new endpoints |
| Brakeman | Static security analysis | Available locally (`bin/brakeman`); not yet enforced in CI (disabled — see [Current Capabilities](#current-capabilities)) |
| SimpleCov | Coverage reporting | Planned |

### Developer Experience

| Tool | Purpose |
|---|---|
| RuboCop (Rails Omakase) | Enforced house code style |
| Brakeman | Security static analysis, run locally via `bin/brakeman` |
| `bin/setup` | One-command environment bootstrap |
| `bin/dev` | Local server start |
| dotenv-rails | Local environment variable management |
| debug | Rails 8 default interactive debugger |

### Deployment

| Technology | Purpose | Why |
|---|---|---|
| Kamal | Containerized, zero-downtime deployment (`config/deploy.yml`) | Deploys to plain servers/containers without adopting a platform sized for a much larger system. |
| Thruster | HTTP asset caching/compression in front of Puma | Avoids standing up a separate reverse proxy for basic HTTP caching. |

## Project Structure

```text
backend/                       # git submodule → github.com/jeanflaragao/backend
├── app/
│   ├── controllers/
│   │   ├── api/v1/            # AuthenticationController, BookmakersController, HealthController
│   │   └── concerns/           # Authenticatable (JWT), ErrorHandler
│   ├── errors/                 # ApplicationError + domain-specific error classes
│   ├── jobs/                   # ApplicationJob (Solid Queue)
│   ├── mailers/
│   ├── models/                 # ApplicationRecord, User, Bookmaker
│   ├── policies/                # Pundit policies (BookmakerPolicy, ...)
│   ├── queries/                 # Filter/search/sort query objects
│   ├── serializers/             # Alba serializers
│   └── services/                 # Business-logic services (Bookmakers::CreateService, Jwt::Encoder/Decoder, ...)
├── config/
│   ├── application.rb          # API-only mode, autoloading
│   ├── database.yml            # PostgreSQL, env-driven credentials
│   ├── deploy.yml               # Kamal deployment config
│   └── routes.rb                # /api/v1: health, login, bookmakers (create/index/show)
├── db/                          # schema + cache/cable/queue tables + seeds
├── spec/                        # RSpec suite: requests, models, policies, services + factories/support
├── .github/
│   ├── workflows/ci.yml         # security scan · lint · test (currently disabled)
│   └── dependabot.yml
├── Dockerfile                   # production multi-stage build
├── Gemfile / Gemfile.lock
└── .rubocop.yml                  # Rails Omakase house style
```

## Architecture Philosophy

The backend is designed as an API-first system with clear boundaries:

- Controllers own transport concerns (HTTP, params, status codes, serialization).
- Services own business workflows and invariants.
- Policies own authorization rules.
- Query objects own complex read composition and filtering.
- Models own persistence mapping and simple invariants.

The architecture should evolve incrementally. Prefer introducing one explicit layer at a time over pre-building abstractions before a real use case exists.

## Engineering Principles

The principles below are used as engineering heuristics rather than rigid rules. Whenever a design decision requires violating one of them, the trade-off should be explicit and documented (see [ADRs](../docs/adr/README.md)).

- **Thin controllers.** Controllers translate HTTP; they do not contain business logic. That logic belongs in service objects.
- **Service objects for use cases.** Multi-step business processes (recording a deposit, reconciling an account) are modeled as single-purpose, testable objects rather than spread across callbacks and controller actions.
- **Separation of concerns.** Persistence (models), authorization (policies), business logic (services), and complex reads (query objects) are deliberately kept in separate layers.
- **SOLID, applied pragmatically.** Single-responsibility objects and dependency boundaries are favored over generic, prematurely abstract frameworks-within-the-framework.
- **Convention over configuration.** Rails defaults are used unless there's a concrete reason to deviate — evidenced by the current API-only, Omakase-styled, database-backed-adapter configuration.
- **RESTful APIs.** Resources and actions are modeled around standard HTTP verbs and status codes.
- **Tests at the boundary.** Request specs are the primary tool for verifying behavior as a client of the API would experience it, complemented by focused unit specs for services and models.
- **CI as a gate, not a formality.** Security scanning, linting, and tests block merges rather than running informationally — a failing build is treated as broken, not as a warning to address later.

## Guiding Principles

These are the underlying values the principles above are derived from.

- Correctness over convenience.
- Explicitness over magic.
- Simplicity over cleverness.
- Testability over shortcuts.
- Observability over assumptions.
- Evolutionary architecture over premature optimization.

## Request Lifecycle

The default request lifecycle for new endpoints should be:

1. Router maps request to a versioned controller action.
2. Controller validates and normalizes input (strong params, coercion).
3. Controller authorizes action via policy.
4. Controller delegates business workflow to a service object.
5. Service performs domain work inside explicit transaction boundaries when needed.
6. Service returns a result object/value that does not depend on HTTP primitives.
7. Controller serializes response and maps failures to consistent API errors.
8. Structured logs and instrumentation are emitted for traceability.

Keep controllers thin: no business branching, no cross-aggregate orchestration, and no hidden side effects.

## Error Handling Strategy

Error handling should be predictable and explicit:

- Use typed/domain-specific exceptions for business failures; avoid generic `StandardError` rescue in domain code.
- Normalize API error responses into a stable envelope (code, message, details, trace/correlation metadata when available).
- Map validation, authorization, not-found, conflict, and unexpected failures to consistent HTTP status codes.
- Log unexpected exceptions with structured context, but never leak sensitive internals in the response body.
- Prefer failing fast for invalid inputs instead of partial processing.

As the API surface grows, centralize error translation in controller concerns or shared middleware to avoid per-controller drift.

## Service Object Guidelines

Service objects should represent a single use case or workflow.

- Naming: use verb-oriented names (`Bookmakers::CreateService`, `Accounts::RecordDepositService`) and keep namespace aligned with the domain area.
- Contract: define explicit inputs and outputs; avoid returning mixed ad-hoc hashes.
- Purity at boundary: accept primitives/value objects where possible and return a predictable result type.
- Transactions: define transaction boundaries in the service when multiple writes must be atomic.
- Side effects: make side effects explicit (events, jobs, notifications), not hidden in callbacks.
- Testability: isolate external dependencies (time, random, gateways) behind injectables or collaborators.

If a service grows multiple reasons to change, split orchestration from domain operations instead of creating a "god service".

## Query Object Guidelines

Use query objects for non-trivial reads (filtering, sorting, pagination, joins).

- Keep query objects read-only; no writes or side effects.
- Compose scopes incrementally (`base_scope -> filters -> sort -> pagination`).
- Whitelist sortable/filterable fields to avoid unsafe dynamic SQL.
- Keep SQL intent readable; prefer Arel/ActiveRecord composition before raw SQL.
- Return relation-like objects when possible to preserve chainability and lazy execution.

When a query becomes domain-critical, document assumptions (indexes, expected cardinality, null behavior).

## Coding Standards

- Follow RuboCop Rails Omakase defaults unless an explicit project exception is documented.
- Favor small methods and intention-revealing names over compact but opaque code.
- Avoid callback-heavy business logic; place workflows in services.
- Keep public interfaces minimal and explicit.
- Document non-obvious decisions with short, high-signal comments.

## Local Development

For the full environment setup (cloning, Docker, `.env`, database prep), see [docs/development](../docs/development/README.md). Once the environment is up:

```bash
cd backend
bundle install
bin/setup   # idempotent: installs deps, prepares db, clears logs/tmp, starts server

# or, if already set up:
bin/dev     # starts Puma on http://localhost:3000

# Verify:
curl http://localhost:3000/up
```

Requires a `.env` (loaded via `dotenv-rails`) with `DATABASE_HOST`, `DATABASE_PORT`, `DATABASE_USERNAME`, `DATABASE_PASSWORD`, `DATABASE_NAME` — `config/database.yml` has no defaults and will fail to connect without them.

## Testing Conventions

The suite is **RSpec + FactoryBot**, run against a real PostgreSQL database (not mocked) — request specs are the default test type for new endpoints, verifying behavior at the HTTP boundary rather than reaching into controller internals. `authenticated_headers(user)` (`spec/support/authentication_helper.rb`, mixed into `type: :request` specs) builds the JWT header for authenticated requests.

Conventions:

- Prefer behavior-focused request specs at the HTTP boundary for API endpoints.
- Add focused unit specs for domain logic in services, policies, and query objects.
- Use FactoryBot factories (`spec/factories`) for test data; avoid fixtures.
- Keep tests deterministic (fixed time/random seeds where relevant).
- Avoid over-mocking ActiveRecord behavior that integration tests can verify more honestly.
- Treat flaky tests as defects and fix before merging.

```bash
bundle exec rspec                                    # full suite
bundle exec rspec spec/models/bookmaker_spec.rb       # single file
bundle exec rspec spec/models/bookmaker_spec.rb:12     # single example at line 12
```

**Planned** (tracked in the [Roadmap](../README.md#roadmap)): **SimpleCov** integrated into CI to track and enforce coverage as the financial-engine domain layer is built out. Brakeman remains the static security gate regardless of coverage tooling.

## Naming Conventions

- Models: singular nouns (`Bookmaker`, `User`).
- Services: domain namespace + verb (`Bookmakers::CreateService`).
- Queries: domain namespace + read intent (`Bookmakers::IndexQuery`, `SearchQuery`).
- Policies: resource + `Policy` suffix.
- Controllers: pluralized resources under explicit API version namespaces.

Name by business intent, not implementation detail.

## Performance Guidelines

- Start with correctness and clarity, then optimize hotspots with evidence.
- Prevent N+1 query patterns in endpoint and query-object paths.
- Add database indexes alongside new high-cardinality filters and uniqueness guarantees.
- Keep payloads lean: serialize only fields required by the contract.
- Use pagination by default for list endpoints.
- Measure before and after optimization changes.

## Security Practices

- Authenticate every non-public endpoint.
- Authorize every action against explicit policy checks.
- Validate and sanitize all external input.
- Never commit secrets; use credentials and environment variables.
- Keep dependencies updated via Dependabot and routine upgrades.
- Run Brakeman and treat findings as merge blockers unless explicitly triaged.

## Code Review Checklist

Before merging, verify:

- The change is aligned with the architecture boundaries in this handbook.
- Business logic is in services, not controllers/models callbacks.
- Authorization and error handling paths are explicit and tested.
- New queries are readable, constrained, and index-aware.
- Tests cover the behavior change (happy path and key failure modes).
- Logging/observability is sufficient for operational debugging.
- Security, linting, and CI checks are green.

## Linting & Security

```bash
bin/rubocop     # Rails Omakase style — .rubocop.yml just inherits the gem's config, no local overrides
bin/brakeman    # static security analysis
```

Both are also scaffolded as independent jobs in `.github/workflows/ci.yml` alongside the test suite, but that workflow is currently disabled (see [Current Capabilities](#current-capabilities)) — run them locally until it's re-enabled.
