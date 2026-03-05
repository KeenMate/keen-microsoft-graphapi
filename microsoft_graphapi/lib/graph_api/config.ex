defmodule GraphApi.Config do
  @moduledoc """
  Configuration struct for Microsoft Graph API client.

  Validates configuration using NimbleOptions. Configuration can come from
  application environment or be passed explicitly for multi-tenant scenarios.

  ## Options

  * `:tenant_id` - Azure AD tenant ID (required)
  * `:client_id` - Application (client) ID (required)
  * `:client_secret` - Client secret (required)
  * `:scope` - OAuth scope (default: `"https://graph.microsoft.com/.default"`)
  * `:api_version` - API version, `:v1` or `:beta` (default: `:v1`)
  * `:base_url` - Graph API base URL (default: derived from `api_version`)

  ## Examples

      # From application config
      config = GraphApi.Config.from_env!()

      # Explicit config
      config = GraphApi.Config.new!(
        tenant_id: "your-tenant-id",
        client_id: "your-client-id",
        client_secret: "your-secret"
      )

      # Beta endpoint
      config = GraphApi.Config.new!(
        tenant_id: "your-tenant-id",
        client_id: "your-client-id",
        client_secret: "your-secret",
        api_version: :beta
      )
  """

  @schema [
    tenant_id: [
      type: :string,
      required: true,
      doc: "Azure AD tenant ID"
    ],
    client_id: [
      type: :string,
      required: true,
      doc: "Application (client) ID"
    ],
    client_secret: [
      type: :string,
      required: true,
      doc: "Client secret"
    ],
    scope: [
      type: :string,
      default: "https://graph.microsoft.com/.default",
      doc: "OAuth scope"
    ],
    api_version: [
      type: {:in, [:v1, :beta]},
      default: :v1,
      doc: "API version (:v1 or :beta)"
    ],
    base_url: [
      type: {:or, [:string, nil]},
      default: nil,
      doc: "Graph API base URL (derived from api_version if not set)"
    ]
  ]

  @type t :: %__MODULE__{
          tenant_id: String.t(),
          client_id: String.t(),
          client_secret: String.t(),
          scope: String.t(),
          api_version: :v1 | :beta,
          base_url: String.t()
        }

  @enforce_keys [:tenant_id, :client_id, :client_secret]
  defstruct [:tenant_id, :client_id, :client_secret, :scope, :api_version, :base_url]

  @doc """
  Creates a new config struct from the given options.

  Returns `{:ok, config}` or `{:error, %NimbleOptions.ValidationError{}}`.
  """
  @spec new(keyword()) :: {:ok, t()} | {:error, NimbleOptions.ValidationError.t()}
  def new(opts) do
    case NimbleOptions.validate(opts, @schema) do
      {:ok, validated} -> {:ok, struct!(__MODULE__, resolve_base_url(validated))}
      {:error, _} = error -> error
    end
  end

  @doc """
  Creates a new config struct from the given options.

  Raises on invalid options.
  """
  @spec new!(keyword()) :: t()
  def new!(opts) do
    validated = NimbleOptions.validate!(opts, @schema)
    struct!(__MODULE__, resolve_base_url(validated))
  end

  @doc """
  Creates a config struct from application environment.

  Reads from `Application.get_env(:keen_microsoft_graphapi, :config)`.
  Raises if the configuration is missing or invalid.
  """
  @spec from_env!() :: t()
  def from_env! do
    opts =
      Application.get_env(:keen_microsoft_graphapi, :config) ||
        raise "Missing :keen_microsoft_graphapi :config in application environment"

    new!(opts)
  end

  @doc """
  Returns the NimbleOptions schema for documentation purposes.
  """
  @spec schema() :: keyword()
  def schema, do: @schema

  @doc """
  Returns the base URL for the given API version.
  """
  @spec base_url_for(:v1 | :beta) :: String.t()
  def base_url_for(:beta), do: "https://graph.microsoft.com/beta"
  def base_url_for(_), do: "https://graph.microsoft.com/v1.0"

  defp resolve_base_url(opts) do
    case Keyword.get(opts, :base_url) do
      nil -> Keyword.put(opts, :base_url, base_url_for(Keyword.get(opts, :api_version, :v1)))
      _url -> opts
    end
  end
end
