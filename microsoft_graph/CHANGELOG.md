# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
  - `MicrosoftGraph.Users` - users CRUD + directReports, memberOf
  - `MicrosoftGraph.Groups` - groups CRUD + members management
  - `MicrosoftGraph.Mail` - messages, sendMail, mailFolders
  - `MicrosoftGraph.Calendar` - events, calendarView, calendars
  - `MicrosoftGraph.Files` - drives, items, upload/download
- Typed error structs (`ApiError`, `AuthError`, `RateLimitError`)
- Retry middleware with `Retry-After` header support
- Multi-tenant support via explicit client passing
