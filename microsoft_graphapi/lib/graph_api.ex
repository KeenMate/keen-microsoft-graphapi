defmodule GraphApi do
  @moduledoc """
  Elixir client for the Microsoft Graph API.

  GraphApi provides a clean, idiomatic interface to Microsoft Graph API resources
  with built-in authentication, OData query building, batch requests, pagination,
  schema casting, and error handling.

  ## Architecture Overview

  ```
  ┌─────────────────────────────────────────────────────────┐
  │                    YOUR APPLICATION                     │
  └─────────────────────────────────────────────────────────┘
                             │
              ┌──────────────┴──────────────┐
              │                             │
              ▼                             ▼
    ┌───────────────────┐       ┌───────────────────┐
    │   App-Only Auth   │       │  Delegated Auth   │
    │ (Client Creds)    │       │ (User OAuth Token) │
    │                   │       │                   │
    │ Config + secret → │       │ access_token per  │
    │ auto token mgmt   │       │ request           │
    └─────────┬─────────┘       └─────────┬─────────┘
              │                           │
              └─────────────┬─────────────┘
                            │
                            ▼
              ┌───────────────────────────┐
              │      GraphApi.Client      │
              │  Req.Request + middleware  │
              └─────────────┬─────────────┘
                            │
              ┌─────────────┼─────────────┐
              │             │             │
              ▼             ▼             ▼
        ┌──────────┐ ┌──────────┐ ┌──────────┐
        │   Auth   │ │  Error   │ │  Retry   │
        │Middleware│ │ Handling │ │Middleware│
        └──────────┘ └──────────┘ └──────────┘
                            │
                            ▼
  ┌─────────────────────────────────────────────────────────┐
  │                  RESOURCE MODULES                       │
  │                                                         │
  │  Users · Groups · Mail · Calendar · Files · Subscriptions│
  │                                                         │
  │  Each function returns {:ok, result} | {:error, error}  │
  │  Each has a _query variant for batch requests            │
  └─────────────────────────┬───────────────────────────────┘
                            │
              ┌─────────────┼─────────────┐
              │             │             │
              ▼             ▼             ▼
        ┌──────────┐ ┌──────────┐ ┌──────────┐
        │  OData   │ │  Batch   │ │  Delta   │
        │  Query   │ │ Requests │ │ Queries  │
        │ Builder  │ │ (up to   │ │ (change  │
        │ + Filter │ │  20/call)│ │ tracking)│
        └──────────┘ └──────────┘ └──────────┘
              │             │             │
              └─────────────┼─────────────┘
                            │
                            ▼
              ┌───────────────────────────┐
              │     Schema Casting        │
              │  JSON → typed structs     │
              │  v1.0 + Beta schemas      │
              │  Views for projections    │
              └───────────────────────────┘
  ```

  ## Authentication Modes

  **App-only (client credentials)** — configure once, tokens managed automatically:

      config :keen_microsoft_graphapi, :config,
        tenant_id: System.fetch_env!("AZURE_TENANT_ID"),
        client_id: System.fetch_env!("AZURE_CLIENT_ID"),
        client_secret: System.fetch_env!("AZURE_CLIENT_SECRET")

      {:ok, users} = GraphApi.Users.list()

  **Delegated (user token)** — pass an OAuth access token per request:

      client = GraphApi.Client.new()
      {:ok, me} = GraphApi.Users.get("me", client: client, access_token: user_token)

  **Multi-tenant** — explicit config per tenant:

      config = GraphApi.Config.new!(tenant_id: "aaa", client_id: "bbb", client_secret: "ccc")
      client = GraphApi.Client.new(config: config)
      {:ok, users} = GraphApi.Users.list(client: client)

  ## Resource Modules

  | Module | Endpoints | Description |
  |--------|-----------|-------------|
  | `GraphApi.Users` | 30 | CRUD, manager, memberships, licenses, photos, auth methods |
  | `GraphApi.Groups` | 26 | CRUD, members, owners, app roles, permission grants |
  | `GraphApi.Mail` | 9 | Messages, send, drafts, folders, delta |
  | `GraphApi.Calendar` | 8 | Events CRUD, calendar view, calendars list |
  | `GraphApi.Files` | 23 | Drives, items, upload/download, permissions, versions |
  | `GraphApi.Subscriptions` | 5 | Webhook subscriptions CRUD |

  Every function has a `_query` variant that returns a `%GraphApi.Batch.Request{}`
  for use in batch operations.

  ## Query Building

      alias GraphApi.OData
      alias GraphApi.OData.Filter
      alias GraphApi.Schema.User

      # Functional OData builder
      query = OData.new()
        |> OData.select(["displayName", "mail"])
        |> OData.filter(User, account_enabled: true)
        |> OData.top(25)

      # Or build complex filters
      filter = Filter.new(User)
        |> Filter.where(:display_name, :starts_with, "A")
        |> Filter.or_where(:department, :eq, "Engineering")

      {:ok, response} = GraphApi.Users.list(query: OData.new() |> OData.filter(filter))

  ## Error Handling

  All operations return `{:ok, result}`, `:ok`, or `{:error, error}`:

  * `GraphApi.Error.ApiError` — non-2xx Graph API responses
  * `GraphApi.Error.AuthError` — authentication failures
  * `GraphApi.Error.RateLimitError` — 429 after retry exhaustion (with `retry_after`)

  ## Key Features

  * **Batch requests** — up to 20 requests per HTTP call via `GraphApi.Batch`
  * **Delta queries** — incremental change tracking via `GraphApi.Delta`
  * **Pagination** — lazy streaming via `GraphApi.Pagination`
  * **Schema casting** — auto-cast JSON to typed structs with the `:as` option
  * **Views** — field projections that auto-inject `$select` via `GraphApi.View`
  * **Webhooks** — parse and validate Graph notifications via `GraphApi.Webhook`
  """
end
