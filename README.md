<div align="center">

# Backend

**Backend Engineering Handbook for the real-money wagering platform.**

[![CI](https://github.com/jeanflaragao/backend/actions/workflows/ci.yml/badge.svg)](https://github.com/jeanflaragao/backend/actions/workflows/ci.yml)
[![Ruby](https://img.shields.io/badge/ruby-3.2-CC342D?logo=ruby&logoColor=white)](Dockerfile)
[![Rails](https://img.shields.io/badge/rails-8.0.5-CC0000?logo=rubyonrails&logoColor=white)](Gemfile.lock)
[![PostgreSQL](https://img.shields.io/badge/postgresql-16-4169E1?logo=postgresql&logoColor=white)](../infra/compose/docker-compose.yml)
[![Coverage](https://img.shields.io/badge/coverage-not--configured-lightgrey)](#testing-conventions)

</div>

> [!IMPORTANT]
> This repository is in its **foundation phase**. Domain logic (accounts, wagering, settlement) has not been implemented yet — see [Current Capabilities](#current-capabilities) for what actually exists, and the root [Roadmap](../README.md#roadmap) for what's planned. This handbook captures both: the system as it exists today, and the engineering standards used to evolve it safely.

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

Everything listed here exists in the codebase today and is exercised by CI. Nothing in this section is aspirational.

**Application**
- Ruby on Rails 8.0.5 configured in API-only mode (`config.api_only = true`) — no view layer, no unnecessary middleware.
- Health-check endpoint (`GET /up`) suitable for load balancer / uptime monitoring integration.
- Encrypted credentials via Rails' built-in credentials store (`config/credentials.yml.enc`), keeping secrets out of source control.
- Database-backed adapters configured for cache, background jobs, and Action Cable (Solid Cache, Solid Queue, Solid Cable) — the Rails 8 default of avoiding a Redis dependency for these concerns.
- One-command environment bootstrap (`bin/setup`) and server start (`bin/dev`).

**CI/CD & Quality Gates**
- GitHub Actions pipeline running on every push and pull request against `main`, with three independent jobs:
  - **Security scanning** — [Brakeman](https://brakemanscanner.org/) static analysis for common Rails vulnerabilities.
  - **Linting** — [RuboCop](https://github.com/rails/rubocop-rails-omakase) with the Rails Omakase house style.
  - **Automated tests** — the Minitest suite, run against a real PostgreSQL service container (not mocked).
- Dependabot configured for both `bundler` and `github-actions` ecosystems, checked daily.
- Kamal deployment configuration scaffolded (`config/deploy.yml`, `.kamal/`) for containerized, zero-downtime deploys, fronted by Thruster for asset caching/compression.

For the target architecture this is being built toward — service objects, policies, query objects — see [docs/architecture/backend.md](../docs/architecture/backend.md).

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
| Solid Cable | Rails 8 default | Database-backed Action Cable adapter | Configured by default; unused until a real-time feature (e.g. live odds) needs it. |
| Bootsnap | latest | Boot-time caching for faster startup | Standard Rails optimization. |

### Testing

| Tool | Role | Status |
|---|---|---|
| Minitest | Default Rails test framework | Present (scaffold, no application tests yet) |
| Brakeman | Static security analysis | Active in CI |
| RSpec + FactoryBot | Target spec-style testing stack | Planned |
| Request specs | HTTP-boundary contract testing | Planned |
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
│   ├── controllers/           # ApplicationController (ActionController::API)
│   ├── jobs/                  # ApplicationJob (Solid Queue)
│   ├── mailers/
│   └── models/                # ApplicationRecord
├── config/
│   ├── application.rb         # API-only mode, autoloading
│   ├── database.yml           # PostgreSQL, env-driven credentials
│   ├── deploy.yml              # Kamal deployment config
│   └── routes.rb               # currently: health check only
├── db/                         # cache/cable/queue schemas + seeds
├── test/                       # Minitest scaffold
├── .github/
│   ├── workflows/ci.yml        # security scan · lint · test
│   └── dependabot.yml
├── Dockerfile                  # production multi-stage build
├── Gemfile / Gemfile.lock
└── .rubocop.yml                 # Rails Omakase house style
```

As services, policies, and query objects are added, they will live under `app/services/`, `app/policies/`, and `app/queries/` respectively, following the layering in [docs/architecture/backend.md](../docs/architecture/backend.md#layer-responsibility-matrix).

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
- **Service objects for use cases.** Multi-step business processes (placing a bet, settling a market) are modeled as single-purpose, testable objects rather than spread across callbacks and controller actions.
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

- Naming: use verb-oriented names (`CreateService`, `SettleMarketService`) and keep namespace aligned with the domain area.
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

The current setup uses Rails' default **Minitest** suite, exercised in CI (`bin/rails db:test:prepare test`) against a real PostgreSQL service container rather than a mocked database — a deliberate choice carried forward as the suite grows, so that CI reflects production database behavior.

Current and target testing conventions:

- Prefer behavior-focused tests at the HTTP boundary for API endpoints.
- Add focused unit tests for domain logic in services, policies, and query objects.
- Keep tests deterministic (fixed time/random seeds where relevant).
- Avoid over-mocking ActiveRecord behavior that integration tests can verify more honestly.
- Treat flaky tests as defects and fix before merging.

No application-level tests exist yet for many business flows, because that domain logic has not been implemented.

```bash
bin/rails test                          # full suite
bin/rails test test/models/foo_test.rb  # single file
bin/rails test test/models/foo_test.rb:12   # single test at line 12
```

Tests run in parallel by default (`parallelize(workers: :number_of_processors)` in `test/test_helper.rb`).

**Planned testing direction** (tracked in the [Roadmap](../README.md#roadmap)):
- Migration to **RSpec** as the primary testing framework, with **FactoryBot** replacing fixtures for test data construction.
- **Request specs** as the default test type for new endpoints — verifying behavior at the HTTP boundary rather than reaching into controller internals.
- **Service specs** covering business logic in isolation from HTTP and persistence concerns.
- **SimpleCov** integrated into CI to track and enforce coverage as the domain layer is built out.
- Brakeman remains as the static security gate regardless of the spec framework used.

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

Both run in CI (`.github/workflows/ci.yml`) alongside the test suite, as independent jobs, on every push and PR to `main`.
