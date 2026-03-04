# Graph Explorer — Implementation Status

Tracking document for the Phoenix LiveView demo UI.

## Architecture

| Component | Status | File |
|---|---|---|
| Phoenix Endpoint | Done | `lib/demo_web/endpoint.ex` |
| Router | Done | `lib/demo_web/router.ex` |
| Error HTML | Done | `lib/demo_web/error_html.ex` |
| Root Layout (CSS + JS) | Done | `lib/demo_web/components/layouts.ex` |
| EndpointCatalog | Done | `lib/demo_web/live/explorer_live/endpoint_catalog.ex` |
| Components (3 columns) | Done | `lib/demo_web/live/explorer_live/components.ex` |
| ExplorerLive | Done | `lib/demo_web/live/explorer_live.ex` |
| ApiExecutor | Done | `lib/demo_web/live/explorer_live/api_executor.ex` |
| Application supervisor | Done | `lib/demo/application.ex` |
| Config (config.exs) | Done | `config/config.exs` |
| Config (dev.exs) | Done | `config/dev.exs` |
| Config (runtime.exs) | Done | `config/runtime.exs` — graceful when env vars missing |
| Dependencies (mix.exs) | Done | `mix.exs` — phoenix, phoenix_html, phoenix_live_view, phoenix_live_reload, bandit |

## UI Features

| Feature | Status | Notes |
|---|---|---|
| 3-column layout (20/30/50) | Done | CSS Grid, each column scrolls independently |
| Endpoint navigator | Done | Grouped by resource, method badges (GET/POST/PATCH/DEL) |
| Parameter builder | Done | Path params, OData fields, JSON body, options |
| Result display | Done | Visual (table/cards) + Raw JSON tabs |
| OData metadata banner | Done | @odata.count, @odata.nextLink, @odata.context |
| Pagination (Load Next Page) | Done | Follows @odata.nextLink, appends items to result |
| Advanced Query toggle | Done | Single checkbox for ConsistencyLevel: eventual + $count=true |
| API version toggle | Done | v1.0 / beta |
| Authentication fields | Done | Tenant ID, Client ID, Client Secret, Access Token in UI |
| Credentials from env vars | Done | Pre-populated on mount if AZURE_* vars are set |
| Body templates | Done | Pre-filled JSON for every mutation endpoint |
| Endpoint descriptions | Done | Shown at top of param builder |
| Loading state | Done | Spinner + disabled Execute button during async call |
| Error display | Done | Red box with formatted error messages |
| Async execution | Done | start_async to avoid blocking the LiveView process |

## Endpoint Coverage

### Users (7 endpoints)

| Endpoint | Function | Method | Path Params | Body | Template | Status |
|---|---|---|---|---|---|---|
| list | `Users.list/1` | GET | — | — | — | Done |
| get | `Users.get/2` | GET | user_id | — | — | Done |
| create | `Users.create/2` | POST | — | Yes | User with passwordProfile | Done |
| update | `Users.update/3` | PATCH | user_id | Yes | jobTitle, department, officeLocation | Done |
| delete | `Users.delete/2` | DELETE | user_id | — | — | Done |
| list_direct_reports | `Users.list_direct_reports/2` | GET | user_id | — | — | Done |
| list_member_of | `Users.list_member_of/2` | GET | user_id | — | — | Done |

### Groups (8 endpoints)

| Endpoint | Function | Method | Path Params | Body | Template | Status |
|---|---|---|---|---|---|---|
| list | `Groups.list/1` | GET | — | — | — | Done |
| get | `Groups.get/2` | GET | group_id | — | — | Done |
| create | `Groups.create/2` | POST | — | Yes | Security group | Done |
| update | `Groups.update/3` | PATCH | group_id | Yes | displayName, description | Done |
| delete | `Groups.delete/2` | DELETE | group_id | — | — | Done |
| list_members | `Groups.list_members/2` | GET | group_id | — | — | Done |
| add_member | `Groups.add_member/3` | POST | group_id, member_id | — | — | Done |
| remove_member | `Groups.remove_member/3` | DELETE | group_id, member_id | — | — | Done |

### Mail (7 endpoints)

| Endpoint | Function | Method | Path Params | Body | Template | Status |
|---|---|---|---|---|---|---|
| list_messages | `Mail.list_messages/2` | GET | user_id | — | — | Done |
| get_message | `Mail.get_message/3` | GET | user_id, message_id | — | — | Done |
| send_mail | `Mail.send_mail/3` | POST | user_id | Yes | Full message with recipients | Done |
| create_draft | `Mail.create_draft/3` | POST | user_id | Yes | Draft with recipients | Done |
| delete_message | `Mail.delete_message/3` | DELETE | user_id, message_id | — | — | Done |
| list_mail_folders | `Mail.list_mail_folders/2` | GET | user_id | — | — | Done |
| list_folder_messages | `Mail.list_folder_messages/3` | GET | user_id, folder_id | — | — | Done |

### Calendar (7 endpoints)

| Endpoint | Function | Method | Path Params | Body | Extra Params | Template | Status |
|---|---|---|---|---|---|---|---|
| list_events | `Calendar.list_events/2` | GET | user_id | — | — | — | Done |
| get_event | `Calendar.get_event/3` | GET | user_id, event_id | — | — | — | Done |
| create_event | `Calendar.create_event/3` | POST | user_id | Yes | — | Event with attendees | Done |
| update_event | `Calendar.update_event/4` | PATCH | user_id, event_id | Yes | — | subject, location | Done |
| delete_event | `Calendar.delete_event/3` | DELETE | user_id, event_id | — | — | — | Done |
| calendar_view | `Calendar.calendar_view/2` | GET | user_id | — | start_date_time, end_date_time | — | Done |
| list_calendars | `Calendar.list_calendars/2` | GET | user_id | — | — | — | Done |

### Files (8 endpoints)

| Endpoint | Function | Method | Path Params | Body | Template | Status |
|---|---|---|---|---|---|---|
| get_drive | `Files.get_drive/2` | GET | user_id | — | — | Done |
| list_root_children | `Files.list_root_children/2` | GET | drive_id | — | — | Done |
| list_children | `Files.list_children/3` | GET | drive_id, item_id | — | — | Done |
| get_item | `Files.get_item/3` | GET | drive_id, item_id | — | — | Done |
| get_item_by_path | `Files.get_item_by_path/3` | GET | drive_id, path | — | — | Done |
| download_content | `Files.download_content/3` | GET | drive_id, item_id | — | — | Done |
| upload_small | `Files.upload_small/4` | POST | drive_id, path | Yes (raw) | Sample text | Done |
| create_upload_session | `Files.create_upload_session/4` | POST | drive_id, path | Yes | conflictBehavior | Done |

## Planned Features

### 1. Response Schema Casting — Pending

The `:as` option already works in the library (`Resource` + `Pagination` support it). Remaining work is demo UI integration.

- Add `schema` field to `%Entry{}` in `endpoint_catalog.ex` (e.g., `MicrosoftGraph.Schema.User` for user endpoints)
- Add "Cast to struct" checkbox in Options section of `components.ex`
- Pass `as: entry.schema` in `api_executor.ex` when checkbox is enabled

### 2. Batch Requests ($batch) — Pending

New module: `MicrosoftGraph.Batch`

```elixir
Batch.request("1", "GET", "/users/user-1")
Batch.request("2", "POST", "/users", body: %{...}, depends_on: ["1"])
{:ok, responses} = Batch.execute(requests, client: client)  # POST /$batch, max 20
Batch.find_response(responses, "1")
```

- Validates max 20 requests per batch
- Reuses existing auth/retry middleware via `Resource.post`
- Demo UI: "Batch" group in endpoint catalog, body template is JSON array of requests

### 3. Delta Queries — Pending

New module: `MicrosoftGraph.Delta`

```elixir
{:ok, %{items, delta_link, next_link}} = Delta.query("/users/delta", client: client)
{:ok, result} = Delta.collect_all("/users/delta", client: client)  # all pages + deltaLink
stream = Delta.stream("/users/delta", client: client)               # lazy
```

- Follows `@odata.nextLink` until `@odata.deltaLink` appears
- Preserves `@removed` items for deletion tracking
- Convenience: `Users.delta/1`, `Groups.delta/1`
- Demo UI: "delta" entries under Users and Groups

### 4. Subscriptions/Webhooks — Pending

New modules: `MicrosoftGraph.Subscriptions` + `MicrosoftGraph.Webhook`

```elixir
# Standard CRUD (same pattern as Users/Groups)
Subscriptions.create(%{"changeType" => "created,updated", "notificationUrl" => ..., "resource" => "users", ...})
Subscriptions.list() | .get(id) | .renew(id, attrs) | .delete(id)

# Webhook helpers for your endpoint
Webhook.classify_request(conn)     # => {:validate, token} | :notification
Webhook.parse_notifications(body)  # => [%{subscriptionId, changeType, resource, ...}]
```

- Demo UI: "Subscriptions" group with 5 entries (create, list, get, renew, delete)

### 5. Schema-Aware OData Filter Builder — Pending

Extend `MicrosoftGraph.OData` with a filter helper that uses schema field mappings to auto-translate snake_case atoms to camelCase API field names.

```elixir
# Today (raw string, must know camelCase names):
OData.filter(query, "department eq 'Engineering' and accountEnabled eq true")

# New (schema-aware, uses snake_case atoms):
import MicrosoftGraph.OData.Filter

query
|> OData.filter(User, fn u ->
  u.department == "Engineering" and u.account_enabled == true
end)

# Or a simpler keyword-based API:
OData.filter(query, User, department: "Engineering", account_enabled: true)
```

- Uses `__field_mapping__/0` from schema modules to convert field names
- Supports common operators: `eq`, `ne`, `gt`, `lt`, `ge`, `le`, `startsWith`, `endsWith`, `contains`
- Supports `and`/`or`/`not` combinators
- Raw string filter still works as fallback for complex expressions

### 6. Delegated Auth Flow (OAuth Authorization Code) — Pending

New module: `MicrosoftGraph.Auth.Delegated`

```elixir
url = Delegated.authorize_url(tenant_id: ..., client_id: ..., redirect_uri: ..., scope: "User.Read", state: ...)
{:ok, tokens} = Delegated.exchange_code(tenant_id: ..., client_id: ..., client_secret: ..., code: ..., redirect_uri: ...)
{:ok, tokens} = Delegated.refresh_token(...)
```

Demo app changes:
- `AuthController` with `/auth/login` (redirect to Microsoft) and `/auth/callback` (exchange code, store token)
- "Sign in with Microsoft" button in auth section of the UI
- Token auto-populated in access_token field after successful sign-in

## How to Run

```bash
cd demo
mix deps.get

# Option A: env vars (pre-populated in UI)
export AZURE_TENANT_ID="..."
export AZURE_CLIENT_ID="..."
export AZURE_CLIENT_SECRET="..."

# Option B: no env vars — fill in the UI directly

iex -S mix
# Open http://localhost:4000
```
