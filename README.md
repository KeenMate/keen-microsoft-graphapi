# Microsoft Graph API — Elixir

This repository contains the **MicrosoftGraph** Elixir library and a companion demo application, organized as sibling Mix projects (poncho layout).

## Structure

| Directory | Description |
|---|---|
| [`microsoft_graph/`](microsoft_graph/) | The library — Elixir client for the Microsoft Graph API |
| [`demo/`](demo/) | Demo app with runnable examples that use the library |

## Getting Started

### Library

See [`microsoft_graph/README.md`](microsoft_graph/README.md) for full documentation, installation, and usage.

```bash
cd microsoft_graph
mix deps.get
mix test
```

### Demo

The demo app depends on the library via a path dependency.

#### Graph Explorer (web UI)

An interactive Phoenix LiveView UI for browsing all library endpoints, configuring OData parameters, and executing calls against a real Azure tenant.

```bash
cd demo
mix deps.get

# Option A: set credentials as env vars (pre-populated in the UI)
export AZURE_TENANT_ID="your-tenant-id"
export AZURE_CLIENT_ID="your-client-id"
export AZURE_CLIENT_SECRET="your-client-secret"

# Option B: skip env vars — enter credentials directly in the browser

iex -S mix
# Open http://localhost:4000
```

Credentials are optional at startup. The UI provides fields for Tenant ID, Client ID, Client Secret, and Access Token — enter or change them at any time in the browser.

#### Programmatic examples

```bash
cd demo
mix deps.get

export AZURE_TENANT_ID="your-tenant-id"
export AZURE_CLIENT_ID="your-client-id"
export AZURE_CLIENT_SECRET="your-client-secret"

mix run -e "Demo.Examples.list_users() |> IO.inspect()"
```

See [`demo/lib/demo/examples.ex`](demo/lib/demo/examples.ex) for all available examples.

## License

MIT — see [`microsoft_graph/LICENSE`](microsoft_graph/LICENSE) for details.
