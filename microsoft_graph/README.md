# MicrosoftGraph

Elixir client for the [Microsoft Graph API](https://learn.microsoft.com/en-us/graph/overview).

Built with [Req](https://hexdocs.pm/req) for modern HTTP handling, featuring automatic token management, OData query building, stream-based pagination, and typed error handling.

## Installation

Add `microsoft_graph` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:microsoft_graph, "~> 0.1.0", organization: "keenmate"}
  ]
end
```

## Configuration

### Single-Tenant Setup

Add to your `config/runtime.exs`:

```elixir
config :microsoft_graph, :config,
  tenant_id: System.fetch_env!("AZURE_TENANT_ID"),
  client_id: System.fetch_env!("AZURE_CLIENT_ID"),
  client_secret: System.fetch_env!("AZURE_CLIENT_SECRET")
```

Then call any resource module directly:

```elixir
{:ok, %{"value" => users}} = MicrosoftGraph.Users.list()
{:ok, user} = MicrosoftGraph.Users.get("user@contoso.com")
```

### Multi-Tenant Setup

Build an explicit client for each tenant:

```elixir
config = MicrosoftGraph.Config.new!(
  tenant_id: "tenant-aaa",
  client_id: "client-bbb",
  client_secret: "secret-ccc"
)

client = MicrosoftGraph.Client.new(config: config)
{:ok, users} = MicrosoftGraph.Users.list(client: client)
```

## OData Queries

Use the functional builder to construct query parameters:

```elixir
alias MicrosoftGraph.OData

query = OData.new()
  |> OData.select(["displayName", "mail", "id"])
  |> OData.filter("department eq 'Engineering'")
  |> OData.top(25)
  |> OData.orderby("displayName")

{:ok, response} = MicrosoftGraph.Users.list(query: query)
```

Supported parameters: `$select`, `$filter`, `$expand`, `$top`, `$skip`, `$orderby`, `$count`, `$search`.

The `$filter` value is a raw string since Graph filter syntax is too varied for a DSL.

## Pagination

Stream-based pagination that lazily follows `@odata.nextLink`:

```elixir
{:ok, first_page} = MicrosoftGraph.Users.list(client: client)

# Lazy stream
all_users = MicrosoftGraph.Pagination.stream(first_page, client: client)
  |> Enum.to_list()

# Or collect all at once
{:ok, all_users} = MicrosoftGraph.Pagination.collect_all(first_page, client: client)
```

## Resource Modules

### Users

```elixir
{:ok, %{"value" => users}} = MicrosoftGraph.Users.list()
{:ok, user} = MicrosoftGraph.Users.get("user-id")
{:ok, user} = MicrosoftGraph.Users.create(%{"displayName" => "Alice", ...})
{:ok, user} = MicrosoftGraph.Users.update("user-id", %{"jobTitle" => "Engineer"})
:ok = MicrosoftGraph.Users.delete("user-id")
{:ok, %{"value" => reports}} = MicrosoftGraph.Users.list_direct_reports("user-id")
{:ok, %{"value" => groups}} = MicrosoftGraph.Users.list_member_of("user-id")
```

### Groups

```elixir
{:ok, %{"value" => groups}} = MicrosoftGraph.Groups.list()
{:ok, group} = MicrosoftGraph.Groups.get("group-id")
{:ok, %{"value" => members}} = MicrosoftGraph.Groups.list_members("group-id")
:ok = MicrosoftGraph.Groups.add_member("group-id", "user-id")
:ok = MicrosoftGraph.Groups.remove_member("group-id", "user-id")
```

### Mail

```elixir
{:ok, %{"value" => messages}} = MicrosoftGraph.Mail.list_messages("user-id")
{:ok, msg} = MicrosoftGraph.Mail.get_message("user-id", "message-id")

:ok = MicrosoftGraph.Mail.send_mail("user-id", %{
  subject: "Hello",
  body: %{contentType: "Text", content: "Hi there"},
  toRecipients: [%{emailAddress: %{address: "bob@contoso.com"}}]
})

{:ok, %{"value" => folders}} = MicrosoftGraph.Mail.list_mail_folders("user-id")
```

### Calendar

```elixir
{:ok, %{"value" => events}} = MicrosoftGraph.Calendar.list_events("user-id")
{:ok, event} = MicrosoftGraph.Calendar.create_event("user-id", %{"subject" => "Meeting"})

{:ok, %{"value" => view}} = MicrosoftGraph.Calendar.calendar_view("user-id",
  start_date_time: "2024-01-01T00:00:00",
  end_date_time: "2024-01-31T23:59:59"
)

{:ok, %{"value" => calendars}} = MicrosoftGraph.Calendar.list_calendars("user-id")
```

### Files (OneDrive/SharePoint)

```elixir
{:ok, drive} = MicrosoftGraph.Files.get_drive("user-id")
{:ok, %{"value" => items}} = MicrosoftGraph.Files.list_root_children("drive-id")
{:ok, item} = MicrosoftGraph.Files.get_item_by_path("drive-id", "Documents/report.docx")
{:ok, content} = MicrosoftGraph.Files.download_content("drive-id", "item-id")
{:ok, item} = MicrosoftGraph.Files.upload_small("drive-id", "path/file.txt", content)
{:ok, session} = MicrosoftGraph.Files.create_upload_session("drive-id", "path/large.zip")
```

## Schema Casting

All resource functions accept an `:as` option to cast responses into typed Elixir structs:

```elixir
alias MicrosoftGraph.Schema.User

# Single item — returns a struct
{:ok, user} = MicrosoftGraph.Users.get("user-id", as: User)
# => %User{id: "abc", display_name: "Alice", mail: "alice@contoso.com", ...}

# List — casts each item in "value"
{:ok, %{"value" => users}} = MicrosoftGraph.Users.list(as: User)
# => [%User{}, %User{}, ...]

# Combine with $select — only fetch the fields you need
query = OData.new() |> OData.select(["id", "displayName", "mail"])
{:ok, %{"value" => users}} = MicrosoftGraph.Users.list(query: query, as: User)
# => [%User{id: "abc", display_name: "Alice", mail: "alice@...", job_title: nil, ...}]
```

Nested objects are recursively cast — e.g., `password_profile` becomes `%PasswordProfile{}`, lists of `assigned_licenses` become `[%AssignedLicense{}]`.

For field projections, define a View module to auto-inject `$select`:

```elixir
defmodule MyApp.UserSummary do
  use MicrosoftGraph.View,
    schema: MicrosoftGraph.Schema.User,
    fields: [:id, :display_name, :mail]
end

# Automatically adds $select=id,displayName,mail
{:ok, %{"value" => users}} = MicrosoftGraph.Users.list(as: MyApp.UserSummary)
# => [%MyApp.UserSummary{id: "abc", display_name: "Alice", mail: "alice@..."}, ...]
```

## Batch Requests

Send up to 20 requests in a single HTTP call using JSON batching. Every resource function has a `_query` variant that returns a `%Batch.Request{}` instead of executing immediately:

```elixir
alias MicrosoftGraph.{Batch, OData, Users, Groups, Calendar}
alias MicrosoftGraph.Schema.{User, Group, Event}

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

### Available `_query` Functions

Every resource function has a corresponding `_query` variant with the same arguments:

| Module | Functions |
|--------|-----------|
| `Users` | `list_query`, `get_query`, `create_query`, `update_query`, `delete_query`, `list_direct_reports_query`, `list_member_of_query` |
| `Groups` | `list_query`, `get_query`, `create_query`, `update_query`, `delete_query`, `list_members_query`, `add_member_query`, `remove_member_query` |
| `Mail` | `list_messages_query`, `get_message_query`, `send_mail_query`, `create_draft_query`, `delete_message_query`, `list_mail_folders_query`, `list_folder_messages_query` |
| `Calendar` | `list_events_query`, `get_event_query`, `create_event_query`, `update_event_query`, `delete_event_query`, `calendar_view_query`, `list_calendars_query` |
| `Files` | `get_drive_query`, `list_root_children_query`, `list_children_query`, `get_item_query`, `get_item_by_path_query`, `download_content_query`, `upload_small_query`, `create_upload_session_query` |

## Delta Queries

Delta queries let you track incremental changes to resources. Instead of fetching the full dataset every time, you get only what changed since your last sync.

### Initial Sync

```elixir
# Fetch all current users + get a delta_link for future syncs
{:ok, page} = MicrosoftGraph.Delta.query("/users/delta", client: client)
# page.items => [all current users]
# page.delta_link => "https://graph...?$deltatoken=..."

# Store delta_link somewhere persistent (database, ETS, etc.)
```

### Incremental Sync

```elixir
# Later, fetch only changes since last sync
{:ok, changes} = MicrosoftGraph.Delta.query(stored_delta_link, client: client)

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
{:ok, result} = MicrosoftGraph.Delta.collect_all("/users/delta", client: client)
# result.items => all items across all pages
# result.delta_link => final delta link for future syncs
```

### Lazy Streaming

Stream items across pages without loading everything into memory:

```elixir
{:ok, first_page} = MicrosoftGraph.Delta.query("/users/delta", client: client)

first_page
|> MicrosoftGraph.Delta.stream(client: client)
|> Stream.filter(fn item -> item["@removed"] == nil end)
|> Enum.each(&process_user/1)
```

### Convenience Functions

Each resource module provides delta shortcuts:

```elixir
# Users
{:ok, page} = MicrosoftGraph.Users.delta(client: client)

# Groups
{:ok, page} = MicrosoftGraph.Groups.delta(client: client)

# Group members
{:ok, page} = MicrosoftGraph.Groups.members_delta("group-id", client: client)

# Mail messages
{:ok, page} = MicrosoftGraph.Mail.messages_delta("user-id", client: client)

# Mail folder messages
{:ok, page} = MicrosoftGraph.Mail.folder_messages_delta("user-id", "folder-id", client: client)

# Calendar events
{:ok, page} = MicrosoftGraph.Calendar.events_delta("user-id", client: client)

# Drive files
{:ok, page} = MicrosoftGraph.Files.drive_delta("drive-id", client: client)
```

### Schema Casting with Delta

Delta queries support `:as` for schema casting. Deleted items (with `@removed`) are kept as raw maps:

```elixir
{:ok, changes} = MicrosoftGraph.Delta.query(delta_link,
  client: client,
  as: MicrosoftGraph.Schema.User
)

Enum.each(changes.items, fn
  %MicrosoftGraph.Schema.User{} = user ->
    IO.puts("Updated: #{user.display_name}")

  %{"@removed" => _} = removed ->
    IO.puts("Deleted: #{removed["id"]}")
end)
```

### Batch Variants

All delta convenience functions have `_query` variants for batch requests:

```elixir
batch =
  Batch.new()
  |> Batch.add("1", Users.delta_query())
  |> Batch.add("2", Groups.delta_query())
```

## Subscriptions & Webhooks

Subscriptions let Microsoft Graph push change notifications to your application via webhooks.

### Managing Subscriptions

```elixir
# Create a subscription
{:ok, sub} = MicrosoftGraph.Subscriptions.create(%{
  "changeType" => "created,updated,deleted",
  "notificationUrl" => "https://example.com/webhook",
  "resource" => "users",
  "expirationDateTime" => "2025-04-01T00:00:00Z",
  "clientState" => "my-secret-state"
})

# List active subscriptions
{:ok, %{"value" => subs}} = MicrosoftGraph.Subscriptions.list()

# Get a specific subscription
{:ok, sub} = MicrosoftGraph.Subscriptions.get("subscription-id")

# Renew before expiration
{:ok, renewed} = MicrosoftGraph.Subscriptions.renew("subscription-id", %{
  "expirationDateTime" => "2025-05-01T00:00:00Z"
})

# Delete
:ok = MicrosoftGraph.Subscriptions.delete("subscription-id")
```

### Handling Webhooks

Use `MicrosoftGraph.Webhook` in your endpoint to handle validation and notification requests:

```elixir
# In your Phoenix controller or Plug router
def webhook(conn, _params) do
  case MicrosoftGraph.Webhook.classify(conn) do
    {:validate, token} ->
      # Microsoft is verifying your endpoint — echo the token back
      conn
      |> put_resp_content_type("text/plain")
      |> send_resp(200, token)

    :notification ->
      notifications = MicrosoftGraph.Webhook.parse_notifications(conn.body_params)

      for n <- notifications do
        # Validate clientState to prevent spoofing
        if MicrosoftGraph.Webhook.valid_client_state?(n, "my-secret-state") do
          MyApp.NotificationWorker.enqueue(n)
        end
      end

      # Must respond within 3 seconds
      send_resp(conn, 202, "")
  end
end
```

### Batch Variants

All subscription functions have `_query` variants:

```elixir
batch =
  Batch.new()
  |> Batch.add("1", Subscriptions.list_query())
  |> Batch.add("2", Subscriptions.create_query(%{"resource" => "users", ...}))
```

## Schema-Aware OData Filter Builder

Build type-safe OData `$filter` expressions using snake_case field names from schema modules. Field names are automatically translated to camelCase API names.

### Simple Keyword Syntax

For equality conditions combined with `and`:

```elixir
alias MicrosoftGraph.Schema.User

OData.new()
|> OData.filter(User, company_name: "Contoso", account_enabled: true)
# => $filter=companyName eq 'Contoso' and accountEnabled eq true
```

### Filter Builder

For complex filters with different operators, `and`/`or` combinations:

```elixir
alias MicrosoftGraph.OData.Filter

filter =
  Filter.new(User)
  |> Filter.where(:display_name, :starts_with, "A")
  |> Filter.where(:account_enabled, :eq, true)
  |> Filter.or_where(:company_name, :eq, "Fabrikam")

OData.new() |> OData.filter(filter)
# => $filter=startsWith(displayName,'A') and accountEnabled eq true or companyName eq 'Fabrikam'
```

### Supported Operators

| Operator | Example | OData Output |
|----------|---------|-------------|
| `:eq` | `where(:mail, :eq, "a@b.com")` | `mail eq 'a@b.com'` |
| `:ne` | `where(:job_title, :ne, "Intern")` | `jobTitle ne 'Intern'` |
| `:gt`, `:lt`, `:ge`, `:le` | `where(:age, :gt, 18)` | `age gt 18` |
| `:starts_with` | `where(:display_name, :starts_with, "A")` | `startsWith(displayName,'A')` |
| `:ends_with` | `where(:mail, :ends_with, "@contoso.com")` | `endsWith(mail,'@contoso.com')` |
| `:contains` | `where(:display_name, :contains, "john")` | `contains(displayName,'john')` |
| `:in` | `where(:employee_type, :in, ["A", "B"])` | `employeeType in ('A','B')` |
| `:is_nil` | `where(:mail, :is_nil, true)` | `mail eq null` |

Raw string filters still work as a fallback for expressions the builder doesn't cover:

```elixir
OData.new() |> OData.filter("department eq 'Engineering' and endsWith(mail,'@contoso.com')")
```

## Error Handling

All operations return `{:ok, result}`, `:ok`, or `{:error, error}`:

```elixir
case MicrosoftGraph.Users.get("user-id") do
  {:ok, user} ->
    IO.puts("Found: #{user["displayName"]}")

  {:error, %MicrosoftGraph.Error.ApiError{status: 404}} ->
    IO.puts("User not found")

  {:error, %MicrosoftGraph.Error.AuthError{}} ->
    IO.puts("Authentication failed")

  {:error, %MicrosoftGraph.Error.RateLimitError{retry_after: seconds}} ->
    IO.puts("Rate limited, retry after #{seconds}s")
end
```

## Testing

The library uses [Req.Test](https://hexdocs.pm/req/Req.Test.html) for stubbing HTTP calls in tests. Pass a pre-configured Req client via the `client:` option:

```elixir
test "lists users" do
  Req.Test.stub(:my_stub, fn conn ->
    Req.Test.json(conn, %{"value" => [%{"id" => "1", "displayName" => "Alice"}]})
  end)

  client = Req.new(plug: {Req.Test, :my_stub})
  assert {:ok, %{"value" => [user]}} = MicrosoftGraph.Users.list(client: client)
  assert user["displayName"] == "Alice"
end
```

## License

MIT - see [LICENSE](LICENSE) for details.
