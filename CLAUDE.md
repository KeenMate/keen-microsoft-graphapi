# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Elixir client library for the Microsoft Graph API (`keen_microsoft_graphapi` hex package). Poncho layout with two sibling Mix projects:

- `microsoft_graphapi/` — the library (main codebase)
- `demo/` — Phoenix LiveView demo app (path dependency on the library)

## Commands

All commands run from the `microsoft_graphapi/` directory:

```bash
cd microsoft_graphapi

# Install dependencies
mix deps.get

# Run all unit tests
mix test

# Run a single test file
mix test test/graph_api/resources/users_test.exs

# Run a single test by line number
mix test test/graph_api/resources/users_test.exs:42

# Integration tests (require .env.test credentials)
mix test --include integration
mix test --include integration_delegated

# Lint and format
mix format --check-formatted
mix credo --strict

# Full quality check (format + credo + dialyzer)
mix quality

# Generate schema modules from Microsoft Graph $metadata XML
mix graph.gen.schema
mix graph.gen.schema --version v1
mix graph.gen.schema --version beta

# Generate docs
mix docs
```

## Architecture

### Request Flow

Every resource function (e.g. `Users.list/1`) delegates to a `_query` variant (e.g. `Users.list_query/1`) that builds a `%Batch.Request{}` struct, then calls `Resource.execute/2` to perform the actual HTTP call. This means the `_query` function is the single source of truth for each endpoint's URL, method, and body.

`GraphApi.Client.new/1` builds a `%Req.Request{}` with three middleware steps attached: `Middleware.Auth` (token injection), `Middleware.ErrorHandling` (response normalization), and `Middleware.Retry` (rate limit/transient retry).

### Key Modules

- **`GraphApi.Resource`** — Internal CRUD wrapper over Req. All resource modules go through this.
- **`GraphApi.Client`** — Builds configured `%Req.Request{}` with middleware. Supports app-only (client credentials), delegated (per-request access_token), and multi-tenant configs.
- **`GraphApi.Config`** — Validated config struct (uses NimbleOptions). Reads from app env or explicit opts.
- **`GraphApi.OData` / `GraphApi.OData.Filter`** — Functional query builder for $select, $filter, $expand, $top, etc. Filter supports schema-aware type-safe expressions.
- **`GraphApi.Response`** — Normalizes Req responses into `{:ok, body}` / `:ok` / `{:error, Error.*}`.
- **`GraphApi.Error`** — Typed errors: `ApiError`, `AuthError`, `RateLimitError`.

### Resource Modules

`GraphApi.Users`, `GraphApi.Groups`, `GraphApi.Mail`, `GraphApi.Calendar`, `GraphApi.Files`, `GraphApi.Subscriptions` — each follows the same pattern of function + `_query` variant.

### Schema System

Schema structs in `lib/graph_api/schema/` (v1.0) and `lib/graph_api/schema/beta/` are **auto-generated** by `mix graph.gen.schema` from Microsoft's $metadata XML. Configuration is in `graph_schema.exs`. Do not edit schema files manually.

Each schema has `from_map/1` (camelCase JSON → snake_case struct), `to_map/1` (reverse), and `__field_mapping__/0`. Nested objects are recursively cast.

`GraphApi.View` is a macro for defining projection structs over schemas — provides compile-time field validation and auto `$select` injection.

### Testing Pattern

Tests use `Req.Test.stub/2` to stub HTTP responses. Each test creates a unique stub name and passes `Req.new(plug: {Req.Test, stub_name})` as the client. JSON fixtures live in `test/fixtures/`. Integration tests are excluded by default (tagged `:integration` / `:integration_delegated`).

### Auth Modes

1. **App-only (client credentials)** — configured via app env or explicit `Config.new!/1`. Token managed automatically by `TokenStore` (ETS-backed GenServer).
2. **Delegated (user OAuth)** — pass `access_token:` per request. `Auth.Delegated` handles the authorization code flow.
3. **Multi-tenant** — pass explicit `config:` to `Client.new/1`.
