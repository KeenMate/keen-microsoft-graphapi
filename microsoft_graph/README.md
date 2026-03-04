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
