# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Rails 8 JSON API (API-only, `ActionController::API`) for managing bookmakers, with JWT authentication, Pundit authorization, and Alba serialization. PostgreSQL database.

## Commands

Setup:

```bash
bundle install
bin/rails db:create db:migrate   # or bin/rails db:prepare
bin/rails db:seed                # optional
```

Run the server:

```bash
bin/rails server        # or bin/dev
```

Tests (RSpec):

```bash
bundle exec rspec                              # full suite
bundle exec rspec spec/models/bookmaker_spec.rb # single file
bundle exec rspec spec/models/bookmaker_spec.rb:12  # single example by line
```

Lint / security:

```bash
bundle exec rubocop
bundle exec brakeman
```

Note: the GitHub Actions workflow (`.github/workflows/ci.yml`) is entirely commented out, so none of the above run automatically on push/PR — run them locally before considering work done.

## Architecture

Requests flow: `config/routes.rb` → namespaced controller (`Api::V1::*`) → Pundit policy → query/service object → Alba serializer.

**Controllers** live under `app/controllers/api/v1`, nested in `Api::V1`, and inherit from `ApplicationController` (< `ActionController::API`). Authenticated endpoints `include Authenticatable` (see below) rather than authenticating in `ApplicationController` itself — `AuthenticationController#create` (login) and `HealthController` intentionally skip it.

**Auth**: `Authenticatable` (`app/controllers/concerns/authenticatable.rb`) is a controller concern that adds a `before_action :authenticate_user!`, reading a `Bearer` token from the `Authorization` header, decoding it via `Jwt::Decoder`, and setting `@current_user`. Tokens are minted by `Jwt::Encoder` with payload `{ user_id: }`. Both live under `app/services/jwt/` and read `Rails.application.credentials.secret_key_base` as the signing key. In specs, use the `authenticated_headers(user)` helper from `spec/support/authentication_helper.rb` (mixed into `type: :request` specs) to build the header.

**Authorization**: Pundit. Policies live in `app/policies`, one per model, plus a nested `Scope` class for index-scoping (e.g. `BookmakerPolicy::Scope#resolve` restricts to records owned by `user`). `ApplicationController` includes `Pundit::Authorization`; policies default-deny (`ApplicationPolicy` returns `false` for every action unless overridden).

**Query objects** (`app/queries`) compose filtering/searching/sorting for index endpoints. The pattern: each query class takes a `relation:` plus its own params, exposes `self.call(...)` (delegating to `new(...).call`), and returns a relation. `Bookmakers::IndexQuery` pipes a relation through `FilterQuery` → `SearchQuery` → `SortQuery` in sequence. `SearchQuery` and `SortQuery` are model-agnostic: they read configuration off the target model via constants — `relation.klass::SEARCHABLE_FIELDS`, `SORTABLE_FIELDS`, `DEFAULT_SORT` (see `Bookmaker`) — so reuse for a new resource means defining those constants on the model rather than writing a new query class. `Bookmakers::FilterQuery` is model-specific and defines its own `FILTERABLE_FIELDS`.

**Service objects** (`app/services`) hold write-side business logic (e.g. `Bookmakers::CreateService`). Convention: `self.call(**kwargs)` delegates to `new(**kwargs).call`; `#call` returns a `{ success:, bookmaker: }` / `{ success:, errors: }` style hash rather than raising, wrapping mutations in `ActiveRecord::Base.transaction` and rescuing `ActiveRecord::RecordInvalid` into the failure branch. `Jwt::Encoder`/`Jwt::Decoder` follow the same `self.call` convention but return plain values.

**Serialization**: Alba (`app/serializers`, `include Alba::Resource`). Attribute names can diverge from the model — e.g. `BookmakerSerializer` exposes model field `website` as JSON key `homepage`.

**Errors**: `app/errors` holds custom exception classes; `ApplicationError` (`StandardError` subclass with `code:`/`message:`) is the base for domain-specific errors, namespaced per resource (e.g. `Bookmakers::ActiveAccountsExistError`). `ErrorHandler` (`app/controllers/concerns/error_handler.rb`) is the controller concern meant to `rescue_from` these and render a consistent `{ error: { code:, message: } }` JSON shape.
