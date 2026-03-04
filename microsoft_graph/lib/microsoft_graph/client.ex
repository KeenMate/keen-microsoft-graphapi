defmodule MicrosoftGraph.Client do
  @moduledoc """
  Builds a configured `%Req.Request{}` with all middleware steps attached.

  ## Usage

      # App-only with client credentials (reads config from application environment)
      client = MicrosoftGraph.Client.new()

      # App-only with explicit config (multi-tenant)
      config = MicrosoftGraph.Config.new!(tenant_id: "...", client_id: "...", client_secret: "...")
      client = MicrosoftGraph.Client.new(config: config)

      # Delegated permissions (no config needed — pass access_token per request)
      client = MicrosoftGraph.Client.new()
      MicrosoftGraph.Users.get("me", client: client, access_token: user_token)

      # Beta endpoint
      client = MicrosoftGraph.Client.new(api_version: :beta)

  The returned client is a `%Req.Request{}` struct that can be passed to
  resource modules via the `client:` option.
  """

  alias MicrosoftGraph.Config
  alias MicrosoftGraph.Middleware

  @doc """
  Creates a new `%Req.Request{}` configured for Microsoft Graph API.

  ## Options

  * `:config` - A `%MicrosoftGraph.Config{}` struct. If not provided, attempts to
    read from application environment. If no environment config exists, creates a
    client without client credentials (for use with per-request `access_token:`).
  * `:token_store` - The token store server (default: `MicrosoftGraph.TokenStore`).
  * `:api_version` - `:v1` or `:beta` (default: `:v1`). Ignored if `:config` is provided
    (uses the config's base_url instead).
  """
  @spec new(keyword()) :: Req.Request.t()
  def new(opts \\ []) do
    config = resolve_config(opts)
    token_store = Keyword.get(opts, :token_store, MicrosoftGraph.TokenStore)
    api_version = Keyword.get(opts, :api_version, :v1)

    base_url =
      if config do
        config.base_url
      else
        Config.base_url_for(api_version)
      end

    request =
      Req.new(
        base_url: base_url,
        headers: [
          {"content-type", "application/json"},
          {"accept", "application/json"}
        ]
      )
      |> Req.Request.register_options([
        :microsoft_graph_config,
        :microsoft_graph_token_store,
        :access_token
      ])
      |> Middleware.Auth.attach()
      |> Middleware.ErrorHandling.attach()
      |> Middleware.Retry.attach()

    request =
      if config do
        request
        |> Req.Request.put_option(:microsoft_graph_config, config)
        |> Req.Request.put_option(:microsoft_graph_token_store, token_store)
      else
        request
      end

    request
  end

  defp resolve_config(opts) do
    case Keyword.fetch(opts, :config) do
      {:ok, config} -> config
      :error -> safe_config_from_env()
    end
  end

  defp safe_config_from_env do
    case Application.get_env(:microsoft_graph, :config) do
      nil -> nil
      opts -> Config.new!(opts)
    end
  end
end
