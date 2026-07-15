<div align="center">

# Backend

**API-only Rails application — the operational core of a real-money wagering system.**

[![CI](https://github.com/jeanflaragao/backend/actions/workflows/ci.yml/badge.svg)](https://github.com/jeanflaragao/backend/actions/workflows/ci.yml)
[![Ruby](https://img.shields.io/badge/ruby-3.2-CC342D?logo=ruby&logoColor=white)](Dockerfile)
[![Rails](https://img.shields.io/badge/rails-8.0.5-CC0000?logo=rubyonrails&logoColor=white)](Gemfile.lock)
[![PostgreSQL](https://img.shields.io/badge/postgresql-16-4169E1?logo=postgresql&logoColor=white)](../infra/compose/docker-compose.yml)
[![Coverage](https://img.shields.io/badge/coverage-not--configured-lightgrey)](#testing-strategy)

</div>

> [!IMPORTANT]
> This repository is in its **foundation phase**. Domain logic (accounts, wagering, settlement) has not been implemented yet — see [Current Capabilities](#current-capabilities) for what actually exists, and the root [Roadmap](../README.md#roadmap) for what's planned. This document describes the target architecture the codebase is being built toward; only Controllers and Models exist in skeletal form today.

This document is the practical guide for an engineer working in this codebase: how it's structured, how to run and test it, and the conventions it follows. For the conceptual design (diagrams, philosophy, why the layers exist), see [docs/architecture/backend.md](../docs/architecture/backend.md).

## Table of Contents

- [Current Capabilities](#current-capabilities)
- [Technology Stack](#technology-stack)
- [Project Structure](#project-structure)
- [Engineering Principles](#engineering-principles)
- [Guiding Principles](#guiding-principles)
- [Local Development](#local-development)
- [Testing Strategy](#testing-strategy)
- [Linting & Security](#linting--security)

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

## Testing Strategy

The current setup uses Rails' default **Minitest** suite, exercised in CI (`bin/rails db:test:prepare test`) against a real PostgreSQL service container rather than a mocked database — a deliberate choice carried forward as the suite grows, so that CI reflects production database behavior. No application-level tests exist yet, since no application logic has been written.

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

## Linting & Security

```bash
bin/rubocop     # Rails Omakase style — .rubocop.yml just inherits the gem's config, no local overrides
bin/brakeman    # static security analysis
```

Both run in CI (`.github/workflows/ci.yml`) alongside the test suite, as independent jobs, on every push and PR to `main`.
