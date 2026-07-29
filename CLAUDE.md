# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository context

This is the `backend` git submodule of the `betting-platform` poly-repo (root repo:
`github.com/jeanflaragao/betting-platform`; this repo: `github.com/jeanflaragao/backend`).
It has its own git history and remote — commit here, not in the root repo, for any
application-code change. The full engineering handbook (tech stack rationale, principles,
conventions) lives in [`README.md`](README.md); this file only covers what a Claude Code
instance needs to act correctly and quickly.

**The README describes target/planned state in a few places that no longer match the code.**
Trust this file and the code itself over the README for the following:
- **Test framework is RSpec + FactoryBot, not Minitest.** There is no `test/` directory;
  Minitest scaffolding has been fully replaced by `spec/`. Use the RSpec commands below.
- **CI is currently disabled.** `.github/workflows/ci.yml` exists but every job is commented
  out — nothing runs automatically on push/PR right now, despite the README describing an
  active three-job pipeline (security scan, lint, test). Don't assume a green CI check on
  GitHub means these gates ran.

## Commands

Run from this directory (`backend/`) unless noted.

```bash
# Setup
bundle install
bin/setup                      # idempotent: installs deps, prepares db, clears logs/tmp, starts server
bin/dev                        # starts Puma on :3000 (if already set up)
curl http://localhost:3000/up  # health check

# Tests (RSpec)
bundle exec rspec                                          # full suite
bundle exec rspec spec/requests/api/v1/bookmakers           # a directory
bundle exec rspec spec/requests/api/v1/bookmakers/destroy_spec.rb       # single file
bundle exec rspec spec/requests/api/v1/bookmakers/destroy_spec.rb:12    # single example at line 12

# Lint & security
bin/rubocop        # Rails Omakase style + rubocop-performance + rubocop-rspec (see .rubocop.yml)
bin/rubocop -A      # autocorrect
bin/brakeman        # static security analysis

# Verify a class autoloads correctly (useful after adding/renaming files under app/)
bin/rails runner 'puts SomeNamespace::SomeClass'
```

Requires a `.env` (loaded via `dotenv-rails`) with `DATABASE_HOST`, `DATABASE_PORT`,
`DATABASE_USERNAME`, `DATABASE_PASSWORD`, `DATABASE_NAME` — `config/database.yml` has no
defaults and fails to connect without them. Infra (PostgreSQL 16) is started from the
**root** repo via `make up` (see root `CLAUDE.md`/`Makefile`).

## Architecture

API-only Rails 8 app (`config.api_only = true`) — no views, no session/cookie middleware, no
asset pipeline. Background jobs/cache/Action Cable use the Rails 8 Solid adapters
(DB-backed, no Redis). Auth is stateless JWT (`Jwt::Encoder`/`Jwt::Decoder`, `HS256`,
`Rails.application.credentials.secret_key_base`) via a `Bearer` token, checked by the
`Authenticatable` controller concern.

Request flow through the layers (see `app/`):

```
router → controller (+ Authenticatable, ErrorHandler concerns)
       → policy (Pundit — authorization)
       → query object (reads) OR service object (writes)
       → model (ActiveRecord)
       → serializer (Alba) → JSON response
```

- `app/controllers/api/v1/` — versioned, namespaced controllers (`Api::V1::*`).
- `app/controllers/concerns/` — `Authenticatable` (JWT auth, `before_action`),
  `ErrorHandler` (`rescue_from` → consistent error JSON).
- `app/policies/` — Pundit policies, one per resource, `ApplicationPolicy` denies by default
  (fail closed).
- `app/queries/` — read-only, chainable query objects (`.call` class method,
  `relation.then { ... }` composition). Some are resource-specific and namespaced
  (`Bookmakers::FilterQuery`); some are intentionally generic and *not* namespaced
  (`SearchQuery`, `SortQuery`), driven by constants (`SEARCHABLE_FIELDS`,
  `SORTABLE_FIELDS`, `DEFAULT_SORT`) declared on the model.
- `app/services/` — write/business-workflow objects (`.call` class method), namespaced by
  domain (`Bookmakers::CreateService`).
- `app/errors/` — domain exceptions inheriting `ApplicationError`, namespaced by domain
  (`Bookmakers::ActiveAccountsExistError`).
- `app/serializers/` — Alba serializers (`include Alba::Resource`); presentation layer,
  decoupled from column names (e.g. `Bookmaker#website` → `homepage` in the API).

**Zeitwerk note**: file path must match the fully-qualified constant name exactly
(`app/services/bookmakers/foo_service.rb` must define `Bookmakers::FooService`). A mismatch
fails silently until something references the constant, then raises `NameError` at
load/boot time. When adding a file under a namespaced directory, verify with
`bin/rails runner 'puts Namespace::ClassName'` before considering the work done.

### Controller guidelines

**Responsibilities**: receive the HTTP request, authenticate, authorize, resolve resources,
delegate the business operation to a service, return the HTTP response.

**Forbidden in controllers**: business rules, complex ActiveRecord queries, passing `params`
directly into services, domain decisions.

**Services** receive only domain objects and primitive values — never `params`, `request`,
`response`, `session`, or `cookies`. A controller must extract/permit/coerce first, then pass
plain values or already-loaded records in.

**Error handling**: business failures raise `ApplicationError` (or a domain subclass under
`app/errors/`). Controllers never rescue business exceptions themselves — `ErrorHandler`
(included in `ApplicationController`) is the single place that translates exceptions into
HTTP responses. Avoid adding a second `rescue_from` for the same exception class elsewhere in
the controller hierarchy — Rails resolves `rescue_from` conflicts by silently using
whichever was registered last, which is easy to get wrong without noticing.

### Naming conventions

- Models: singular nouns (`Bookmaker`, `User`).
- Services: domain namespace + verb (`Bookmakers::CreateService`).
- Queries: domain namespace + read intent (`Bookmakers::IndexQuery`), or unnamespaced when
  intentionally generic across models (`SearchQuery`).
- Policies: resource + `Policy` suffix (`BookmakerPolicy`).
- Controllers: pluralized resource under an explicit API version namespace
  (`Api::V1::BookmakersController`).

### Further reading

- [`README.md`](README.md) — full engineering handbook (principles, testing/performance/
  security conventions, code review checklist).
- [`docs/architecture/bookmakers-ecosystem.md`](docs/architecture/bookmakers-ecosystem.md) —
  deep dive on the bookmakers CRUD slice: every layer explained with real code, plus known
  architectural inconsistencies (e.g. authorization is currently done three different ways
  across `index`/`show`/`destroy` in the same controller) worth knowing before extending it.
- `../docs/architecture/backend.md`, `../docs/adr/README.md` (root repo) — target
  architecture and ADRs for cross-cutting decisions.
