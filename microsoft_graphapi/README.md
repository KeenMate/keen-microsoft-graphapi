# GraphApi

Elixir client for the [Microsoft Graph API](https://learn.microsoft.com/en-us/graph/overview).

Built with [Req](https://hexdocs.pm/req) for modern HTTP handling, featuring automatic token management, OData query building, stream-based pagination, and typed error handling.

## Installation

Add `keen_microsoft_graphapi` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:keen_microsoft_graphapi, "~> 1.0.0-rc.1"}
  ]
end
```

## Configuration

### Single-Tenant Setup

Add to your `config/runtime.exs`:

```elixir
config :keen_microsoft_graphapi, :config,
  tenant_id: System.fetch_env!("AZURE_TENANT_ID"),
  client_id: System.fetch_env!("AZURE_CLIENT_ID"),
  client_secret: System.fetch_env!("AZURE_CLIENT_SECRET")
```

Then call any resource module directly:

```elixir
{:ok, %{"value" => users}} = GraphApi.Users.list()
{:ok, user} = GraphApi.Users.get("user@contoso.com")
```

### Multi-Tenant Setup

Build an explicit client for each tenant:

```elixir
config = GraphApi.Config.new!(
  tenant_id: "tenant-aaa",
  client_id: "client-bbb",
  client_secret: "secret-ccc"
)

client = GraphApi.Client.new(config: config)
{:ok, users} = GraphApi.Users.list(client: client)
```

## OData Queries

Use the functional builder to construct query parameters:

```elixir
alias GraphApi.OData

query = OData.new()
  |> OData.select(["displayName", "mail", "id"])
  |> OData.filter("department eq 'Engineering'")
  |> OData.top(25)
  |> OData.orderby("displayName")

{:ok, response} = GraphApi.Users.list(query: query)
```

Supported parameters: `$select`, `$filter`, `$expand`, `$top`, `$skip`, `$orderby`, `$count`, `$search`.

### Schema-Aware Filter Builder

Build type-safe `$filter` expressions using snake_case field names from schema modules:

```elixir
alias GraphApi.OData.Filter
alias GraphApi.Schema.User

# Simple keyword syntax for equality conditions
query = OData.new()
  |> OData.filter(User, company_name: "Contoso", account_enabled: true)
# => $filter=companyName eq 'Contoso' and accountEnabled eq true

# Full builder for complex filters
filter =
  Filter.new(User)
  |> Filter.where(:display_name, :starts_with, "A")
  |> Filter.where(:account_enabled, :eq, true)
  |> Filter.or_where(:company_name, :eq, "Fabrikam")

OData.new() |> OData.filter(filter)
# => $filter=startsWith(displayName,'A') and accountEnabled eq true or companyName eq 'Fabrikam'
```

Supported operators: `:eq`, `:ne`, `:gt`, `:lt`, `:ge`, `:le`, `:starts_with`, `:ends_with`, `:contains`, `:in`, `:is_nil`. Raw string filters still work as a fallback.

## Schema Casting

All resource functions accept an `:as` option to cast responses into typed Elixir structs:

```elixir
alias GraphApi.Schema.User

# Single item — returns a struct
{:ok, user} = GraphApi.Users.get("user-id", as: User)
# => %User{id: "abc", display_name: "Alice", mail: "alice@contoso.com", ...}

# List — casts each item in "value"
{:ok, %{"value" => users}} = GraphApi.Users.list(as: User)
# => [%User{}, %User{}, ...]

# Combine with $select — only fetch the fields you need
query = OData.new() |> OData.select(["id", "displayName", "mail"])
{:ok, %{"value" => users}} = GraphApi.Users.list(query: query, as: User)
# => [%User{id: "abc", display_name: "Alice", mail: "alice@...", job_title: nil, ...}]
```

Nested objects are recursively cast — e.g., `password_profile` becomes `%PasswordProfile{}`, lists of `assigned_licenses` become `[%AssignedLicense{}]`.

For field projections, define a View module to auto-inject `$select`:

```elixir
defmodule MyApp.UserSummary do
  use GraphApi.View,
    schema: GraphApi.Schema.User,
    fields: [:id, :display_name, :mail]
end

# Automatically adds $select=id,displayName,mail
{:ok, %{"value" => users}} = GraphApi.Users.list(as: MyApp.UserSummary)
# => [%MyApp.UserSummary{id: "abc", display_name: "Alice", mail: "alice@..."}, ...]
```

## Pagination

Stream-based pagination that lazily follows `@odata.nextLink`:

```elixir
{:ok, first_page} = GraphApi.Users.list(client: client)

# Lazy stream
all_users = GraphApi.Pagination.stream(first_page, client: client)
  |> Enum.to_list()

# Or collect all at once
{:ok, all_users} = GraphApi.Pagination.collect_all(first_page, client: client)
```

## Batch Requests

Send up to 20 requests in a single HTTP call using JSON batching. Every resource function has a `_query` variant that returns a `%Batch.Request{}` instead of executing immediately:

```elixir
alias GraphApi.{Batch, OData, Users, Groups, Calendar}
alias GraphApi.Schema.{User, Group, Event}

query = OData.new() |> OData.select(["id", "displayName"]) |> OData.top(5)

{:ok, responses} =
  Batch.new()
  |> Batch.add("1", Users.list_query(query: query, as: User))
  |> Batch.add("2", Groups.get_query("group-id", as: Group))
  |> Batch.add("3", Calendar.list_events_query("user-id", as: Event))
  |> Batch.execute(client: client)
```

Each response is individually accessible and auto-cast to its schema:

```elixir
%{status: 200, body: %{"value" => users}} = Batch.get(responses, "1")
# users => [%User{id: "...", display_name: "Alice"}, ...]

%{status: 200, body: group} = Batch.get(responses, "2")
# group => %Group{id: "...", display_name: "Engineering"}
```

### Sequential Dependencies

Use `depends_on` to control execution order within a batch:

```elixir
Batch.new()
|> Batch.add("1", Users.create_query(%{"displayName" => "New User"}, as: User))
|> Batch.add("2", Groups.add_member_query("group-id", "new-user-id"), depends_on: ["1"])
|> Batch.execute(client: client)
```

## Delta Queries

Delta queries let you track incremental changes to resources. Instead of fetching the full dataset every time, you get only what changed since your last sync.

### Initial Sync

```elixir
# Fetch all current users + get a delta_link for future syncs
{:ok, page} = GraphApi.Delta.query("/users/delta", client: client)
# page.items => [all current users]
# page.delta_link => "https://graph...?$deltatoken=..."

# Store delta_link somewhere persistent (database, ETS, etc.)
```

### Incremental Sync

```elixir
# Later, fetch only changes since last sync
{:ok, changes} = GraphApi.Delta.query(stored_delta_link, client: client)

for item <- changes.items do
  case item do
    %{"@removed" => %{"reason" => reason}} ->
      # Item was deleted
      delete_from_local_store(item["id"])

    user ->
      # Item was created or updated
      upsert_local_store(user)
  end
end

# Store the new delta_link for next sync
save_delta_link(changes.delta_link)
```

### Collect All Pages

For initial syncs that span multiple pages, `collect_all/2` follows all `@odata.nextLink` pages automatically:

```elixir
{:ok, result} = GraphApi.Delta.collect_all("/users/delta", client: client)
# result.items => all items across all pages
# result.delta_link => final delta link for future syncs
```

### Lazy Streaming

Stream items across pages without loading everything into memory:

```elixir
{:ok, first_page} = GraphApi.Delta.query("/users/delta", client: client)

first_page
|> GraphApi.Delta.stream(client: client)
|> Stream.filter(fn item -> item["@removed"] == nil end)
|> Enum.each(&process_user/1)
```

### Schema Casting with Delta

Delta queries support `:as` for schema casting. Deleted items (with `@removed`) are kept as raw maps:

```elixir
{:ok, changes} = GraphApi.Delta.query(delta_link,
  client: client,
  as: GraphApi.Schema.User
)

Enum.each(changes.items, fn
  %GraphApi.Schema.User{} = user ->
    IO.puts("Updated: #{user.display_name}")

  %{"@removed" => _} = removed ->
    IO.puts("Deleted: #{removed["id"]}")
end)
```

## Error Handling

All operations return `{:ok, result}`, `:ok`, or `{:error, error}`:

```elixir
case GraphApi.Users.get("user-id") do
  {:ok, user} ->
    IO.puts("Found: #{user["displayName"]}")

  {:error, %GraphApi.Error.ApiError{status: 404}} ->
    IO.puts("User not found")

  {:error, %GraphApi.Error.AuthError{}} ->
    IO.puts("Authentication failed")

  {:error, %GraphApi.Error.RateLimitError{retry_after: seconds}} ->
    IO.puts("Rate limited, retry after #{seconds}s")
end
```

## Delegated Auth (OAuth Authorization Code Flow)

For accessing resources on behalf of a signed-in user (delegated permissions), use the authorization code flow:

### Step 1: Redirect to Microsoft Login

```elixir
alias GraphApi.Auth.Delegated

url = Delegated.authorize_url(
  tenant_id: "your-tenant-id",
  client_id: "your-client-id",
  redirect_uri: "http://localhost:4000/auth/callback",
  scope: "User.Read Mail.Read offline_access",
  state: generate_csrf_token()
)

# Redirect the user to this URL
```

### Step 2: Exchange Code for Tokens

```elixir
# In your callback handler
{:ok, tokens} = Delegated.exchange_code(
  tenant_id: "your-tenant-id",
  client_id: "your-client-id",
  client_secret: "your-client-secret",
  code: params["code"],
  redirect_uri: "http://localhost:4000/auth/callback"
)

# tokens.access_token — use for API calls
# tokens.refresh_token — store for refreshing later
# tokens.expires_in — seconds until expiry
```

### Step 3: Refresh When Expired

```elixir
{:ok, new_tokens} = Delegated.refresh_token(
  tenant_id: "your-tenant-id",
  client_id: "your-client-id",
  client_secret: "your-client-secret",
  refresh_token: stored_refresh_token
)
```

### Using the Token

Pass the delegated access token via the `:access_token` option:

```elixir
{:ok, me} = GraphApi.Users.get("me", access_token: tokens.access_token)
{:ok, messages} = GraphApi.Mail.list_messages("me", access_token: tokens.access_token)
```

## Testing

The library uses [Req.Test](https://hexdocs.pm/req/Req.Test.html) for stubbing HTTP calls in tests. Pass a pre-configured Req client via the `client:` option:

```elixir
test "lists users" do
  Req.Test.stub(:my_stub, fn conn ->
    Req.Test.json(conn, %{"value" => [%{"id" => "1", "displayName" => "Alice"}]})
  end)

  client = Req.new(plug: {Req.Test, :my_stub})
  assert {:ok, %{"value" => [user]}} = GraphApi.Users.list(client: client)
  assert user["displayName"] == "Alice"
end
```

---

## Resource Modules

### Users

```elixir
{:ok, %{"value" => users}} = GraphApi.Users.list()
{:ok, user} = GraphApi.Users.get("user-id")
{:ok, user} = GraphApi.Users.create(%{"displayName" => "Alice", ...})
{:ok, user} = GraphApi.Users.update("user-id", %{"jobTitle" => "Engineer"})
:ok = GraphApi.Users.delete("user-id")
{:ok, %{"value" => reports}} = GraphApi.Users.list_direct_reports("user-id")
{:ok, %{"value" => groups}} = GraphApi.Users.list_member_of("user-id")
```

### Groups

```elixir
{:ok, %{"value" => groups}} = GraphApi.Groups.list()
{:ok, group} = GraphApi.Groups.get("group-id")
{:ok, %{"value" => members}} = GraphApi.Groups.list_members("group-id")
:ok = GraphApi.Groups.add_member("group-id", "user-id")
:ok = GraphApi.Groups.remove_member("group-id", "user-id")
```

### Mail

```elixir
{:ok, %{"value" => messages}} = GraphApi.Mail.list_messages("user-id")
{:ok, msg} = GraphApi.Mail.get_message("user-id", "message-id")

:ok = GraphApi.Mail.send_mail("user-id", %{
  subject: "Hello",
  body: %{contentType: "Text", content: "Hi there"},
  toRecipients: [%{emailAddress: %{address: "bob@contoso.com"}}]
})

{:ok, %{"value" => folders}} = GraphApi.Mail.list_mail_folders("user-id")
```

### Calendar

```elixir
{:ok, %{"value" => events}} = GraphApi.Calendar.list_events("user-id")
{:ok, event} = GraphApi.Calendar.create_event("user-id", %{"subject" => "Meeting"})

{:ok, %{"value" => view}} = GraphApi.Calendar.calendar_view("user-id",
  start_date_time: "2024-01-01T00:00:00",
  end_date_time: "2024-01-31T23:59:59"
)

{:ok, %{"value" => calendars}} = GraphApi.Calendar.list_calendars("user-id")
```

### Files (OneDrive/SharePoint)

```elixir
{:ok, drive} = GraphApi.Files.get_drive("user-id")
{:ok, %{"value" => items}} = GraphApi.Files.list_root_children("drive-id")
{:ok, item} = GraphApi.Files.get_item_by_path("drive-id", "Documents/report.docx")
{:ok, content} = GraphApi.Files.download_content("drive-id", "item-id")
{:ok, item} = GraphApi.Files.upload_small("drive-id", "path/file.txt", content)
{:ok, session} = GraphApi.Files.create_upload_session("drive-id", "path/large.zip")
```

### Subscriptions & Webhooks

```elixir
# Create a subscription
{:ok, sub} = GraphApi.Subscriptions.create(%{
  "changeType" => "created,updated,deleted",
  "notificationUrl" => "https://example.com/webhook",
  "resource" => "users",
  "expirationDateTime" => "2025-04-01T00:00:00Z",
  "clientState" => "my-secret-state"
})

# Handle webhook notifications
case GraphApi.Webhook.classify(conn) do
  {:validate, token} -> send_resp(conn, 200, token)
  :notification ->
    notifications = GraphApi.Webhook.parse_notifications(conn.body_params)
    Enum.each(notifications, &MyApp.NotificationWorker.enqueue/1)
    send_resp(conn, 202, "")
end
```

## License

MIT - see [LICENSE](LICENSE) for details.
