defmodule MicrosoftGraph do
  @moduledoc """
  Elixir client for the Microsoft Graph API.

  `@keenmate/microsoft_graph` provides a clean, idiomatic interface to
  Microsoft Graph API resources with built-in authentication, OData query
  building, pagination, and error handling.

  ## Quick Start — App-Only (Client Credentials)

  Add configuration to your `config/runtime.exs`:

      config :microsoft_graph, :config,
        tenant_id: System.fetch_env!("AZURE_TENANT_ID"),
        client_id: System.fetch_env!("AZURE_CLIENT_ID"),
        client_secret: System.fetch_env!("AZURE_CLIENT_SECRET")

  Then call any resource module:

      {:ok, %{"value" => users}} = MicrosoftGraph.Users.list()
      {:ok, user} = MicrosoftGraph.Users.get("user@contoso.com")

  ## Delegated Permissions (User Access Token)

  If your app authenticates users via OAuth (auth code flow, PKCE, etc.),
  pass the user's access token per request:

      # Create a shared client (no config needed)
      client = MicrosoftGraph.Client.new()

      # Each request carries the user's own token
      {:ok, me} = MicrosoftGraph.Users.get("me",
        client: client,
        access_token: current_user.graph_token
      )

      {:ok, %{"value" => messages}} = MicrosoftGraph.Mail.list_messages("me",
        client: client,
        access_token: current_user.graph_token
      )

  ## Beta Endpoint

      # Client-level
      client = MicrosoftGraph.Client.new(api_version: :beta)
      {:ok, users} = MicrosoftGraph.Users.list(client: client)

      # Per-request override
      {:ok, users} = MicrosoftGraph.Users.list(api_version: :beta)

      # Via config
      config = MicrosoftGraph.Config.new!(
        tenant_id: "...", client_id: "...", client_secret: "...",
        api_version: :beta
      )

  ## OData Queries

      alias MicrosoftGraph.OData

      query = OData.new()
        |> OData.select(["displayName", "mail", "id"])
        |> OData.filter("department eq 'Engineering'")
        |> OData.top(25)

      {:ok, response} = MicrosoftGraph.Users.list(query: query)

  ## Multi-Tenant

      config = MicrosoftGraph.Config.new!(
        tenant_id: "tenant-aaa",
        client_id: "client-bbb",
        client_secret: "secret-ccc"
      )
      client = MicrosoftGraph.Client.new(config: config)
      {:ok, users} = MicrosoftGraph.Users.list(client: client)

  ## Pagination

      {:ok, first_page} = MicrosoftGraph.Users.list(client: client)
      all_users = MicrosoftGraph.Pagination.stream(first_page, client: client)
        |> Enum.to_list()

  ## Resource Modules

  * `MicrosoftGraph.Users` — users CRUD + directReports, memberOf
  * `MicrosoftGraph.Groups` — groups CRUD + members
  * `MicrosoftGraph.Mail` — messages, sendMail, mailFolders
  * `MicrosoftGraph.Calendar` — events, calendarView, calendars
  * `MicrosoftGraph.Files` — drives, items, upload/download

  ## Error Handling

  All operations return `{:ok, result}` or `{:error, error}`. Errors are
  typed structs:

  * `MicrosoftGraph.Error.ApiError` — non-2xx Graph API responses
  * `MicrosoftGraph.Error.AuthError` — authentication failures
  * `MicrosoftGraph.Error.RateLimitError` — 429 after retry exhaustion
  """
end
