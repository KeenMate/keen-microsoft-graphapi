# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0-rc.1] - 2026-03-05

### Changed

- **Package renamed** to `:keen_microsoft_graphapi` (Hex organization: `keenmate`)
- **Module prefix renamed** from `MicrosoftGraph` to `GraphApi` to follow Elixir naming conventions
- **Config atom** changed from `:microsoft_graph` to `:keen_microsoft_graphapi`

### Added

- **Files (OneDrive)** — 14 new endpoints (9 → 23 total):
  `list_drives`, `get_special_folder`, `search`, `create_folder`, `update_item`,
  `delete_item`, `copy_item`, `list_permissions`, `create_sharing_link`,
  `add_permission`, `delete_permission`, `list_versions`, `list_thumbnails`,
  `get_shared_item`
- **Groups** — 9 new endpoints (17 → 26 total):
  `list_transitive_member_of`, `get_member_objects`, `get_member_groups`,
  `check_member_objects`, `check_member_groups`, `list_app_role_assignments`,
  `add_app_role_assignment`, `remove_app_role_assignment`, `list_permission_grants`
- **Users** — complete endpoint coverage (30 endpoints) with CRUD, manager hierarchy,
  memberships, app roles, licenses, authentication methods, photos, and delta queries
- Schema-aware OData filter builder with snake_case field names
- Delegated auth flow (OAuth authorization code)
- Client-request-id header support for request correlation
- `GRAPH_API_COVERAGE.md` — full endpoint coverage map (101 endpoints implemented)

## [0.2.0] - 2026-02-25

### Added

- **Graph Explorer** — interactive Phoenix LiveView UI in the demo app
  - 3-column layout: endpoint navigator, parameter builder, result display
  - Covers all 37 library endpoints across Users, Groups, Mail, Calendar, and Files
  - Endpoint descriptions and JSON body templates pre-filled for every mutation endpoint
  - OData query builder with $select, $filter, $top, $skip, $orderby, $expand, $count, $search
  - Visual (table/cards) and raw JSON result views with @odata metadata banner
  - **Pagination** — "Load Next Page" button follows `@odata.nextLink`, appends results
  - **Advanced Query** toggle — single checkbox enables both `ConsistencyLevel: eventual` header and `$count=true` (required for $search, $count, certain $filter/$orderby)
  - Authentication fields in the UI — Tenant ID, Client ID, Client Secret, and Access Token
  - Credentials pre-populated from environment variables when available
  - Works without env vars configured — enter credentials directly in the browser
  - API version toggle (v1.0 / beta)
  - Async execution with loading state via `start_async`
- Phoenix LiveView with no JS build pipeline — CSS embedded inline, LiveView JS served from deps
- Bandit as the HTTP server for the demo app

## [0.1.0] - 2024-01-15

### Added

- Initial release
- Client credentials (app-only) authentication with Entra ID
- Token caching with proactive refresh via GenServer
- OData query builder (`$select`, `$filter`, `$expand`, `$top`, `$skip`, `$orderby`, `$count`, `$search`)
- Stream-based pagination following `@odata.nextLink`
- Resource modules:
  - `GraphApi.Users` - users CRUD + directReports, memberOf
  - `GraphApi.Groups` - groups CRUD + members management
  - `GraphApi.Mail` - messages, sendMail, mailFolders
  - `GraphApi.Calendar` - events, calendarView, calendars
  - `GraphApi.Files` - drives, items, upload/download
- Typed error structs (`ApiError`, `AuthError`, `RateLimitError`)
- Retry middleware with `Retry-After` header support
- Multi-tenant support via explicit client passing
