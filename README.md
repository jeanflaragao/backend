# Betting Platform Backend

Rails 8 JSON API for managing bookmakers with JWT authentication, Pundit authorization, and query features (filter, search, sort, pagination).

## Stack

- Ruby on Rails 8
- PostgreSQL
- JWT (`jwt` gem)
- Authorization with Pundit
- Serialization with Alba
- Pagination with Pagy
- Testing with RSpec + FactoryBot
- Code quality with RuboCop + Brakeman

## Requirements

- Ruby (compatible with this project and `Gemfile.lock`)
- Bundler
- PostgreSQL

## Credentials Setup

Rails uses encrypted credentials.

The following file is NOT committed:

`config/master.key`

If you are setting up the project for the first time and do not have a master key, generate new credentials:

```bash
EDITOR=nano bundle exec rails credentials:edit
```

This is part of the process to start the app.

## Setup

1. Install dependencies:

```bash
bundle install
```

2. Configure credentials:

JWT encoding/decoding uses `Rails.application.credentials.secret_key_base`.

If your environment requires it, provide `RAILS_MASTER_KEY` so encrypted credentials can be read.

3. Create and migrate the database:

```bash
bin/rails db:create db:migrate
```

4. (Optional) Seed data:

```bash
bin/rails db:seed
```

5. Start the server:

```bash
bin/rails server
```

The API will be available at `http://localhost:3000`.

## Running with Docker

Build and run with Docker:

```bash
docker build -t betting-platform-backend .
docker run --rm -p 3000:3000 --env RAILS_MASTER_KEY=your_master_key betting-platform-backend
```

## API Endpoints

Base path: `/api/v1`

### Health

- `GET /api/v1/health`

### Authentication

- `POST /api/v1/login`

Request body:

```json
{
  "email": "user@example.com",
  "password": "password"
}
```

Success response:

```json
{
  "token": "<jwt-token>"
}
```

Failure response:

```json
{
  "error": "Invalid credentials"
}
```

### Bookmakers (authenticated)

All bookmaker endpoints require:

```http
Authorization: Bearer <jwt-token>
```

- `GET /api/v1/bookmakers`
- `GET /api/v1/bookmakers/:id`
- `POST /api/v1/bookmakers`

#### Create bookmaker

Request body:

```json
{
  "bookmaker": {
    "name": "Bookmaker Name",
    "website": "https://example.com",
    "country": "BR",
    "status": "active"
  }
}
```

Validation notes:

- `name` is required and unique.

#### List bookmaker query params

- `status` (filter)
- `country` (filter)
- `search` (matches `name` and `country`, case-insensitive)
- `sort` (`name`, `country`, `created_at`, `updated_at`)
- `direction` (`asc` or `desc`, defaults to `desc`)
- Pagination params provided by Pagy (`page`, `items`)

Default ordering: `created_at desc`.

## Authorization Rules

Bookmakers are user-owned records.

- Listing returns only bookmakers that belong to the authenticated user.
- Showing a bookmaker is allowed only if it belongs to the authenticated user.

## Serialization

Bookmaker JSON includes:

- `id`
- `name`
- `country`
- `status`
- `homepage` (mapped from model field `website`)

## Testing

Run the full test suite:

```bash
bundle exec rspec
```

Run a specific spec file:

```bash
bundle exec rspec spec/models/bookmaker_spec.rb
```

## Lint and Security Checks

Run RuboCop:

```bash
bundle exec rubocop
```

Run Brakeman:

```bash
bundle exec brakeman
```

## Useful Commands

- `bin/setup` - Install dependencies and prepare local environment.
- `bin/dev` - Start development processes.
- `bin/rails routes` - List all routes.

## Project Structure (high level)

- `app/controllers/api/v1` - API controllers (`authentication`, `bookmakers`, `health`)
- `app/services` - Business logic services (JWT, bookmakers, accounts)
- `app/queries` - Query objects for filter/search/sort composition
- `app/policies` - Pundit authorization policies
- `app/serializers` - Alba serializers
- `spec` - Automated tests
