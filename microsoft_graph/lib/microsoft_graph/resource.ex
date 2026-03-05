defmodule MicrosoftGraph.Resource do
  @moduledoc false
  # Internal helper that wraps Req calls for CRUD operations on Graph resources.
  # Used by resource modules (Users, Groups, etc.) to avoid repetition.

  alias MicrosoftGraph.Client
  alias MicrosoftGraph.Config
  alias MicrosoftGraph.OData
  alias MicrosoftGraph.Response

  @doc """
  Resolves a Req client from the given options.

  If `opts[:client]` is present, returns it. Otherwise builds a new client
  from application config.
  """
  @spec resolve_client(keyword()) :: Req.Request.t()
  def resolve_client(opts) do
    Keyword.get_lazy(opts, :client, fn -> Client.new() end)
  end

  @doc """
  Executes a `%Batch.Request{}` as a real HTTP call.

  The request struct provides method, URL, body, query, and schema casting.
  Remaining options (`:client`, `:access_token`, `:api_version`, `:params`)
  are taken from `opts`.

  This is the bridge between `_query` builders and actual HTTP execution,
  used internally by resource modules so the `_query` function is the
  single source of truth for each endpoint's URL, method, and body.
  """
  @spec execute(MicrosoftGraph.Batch.Request.t(), keyword()) ::
          {:ok, map()} | :ok | {:error, term()}
  def execute(%MicrosoftGraph.Batch.Request{} = req, opts \\ []) do
    # Use as/query from the request (canonical source), keep the rest from opts
    opts =
      opts
      |> Keyword.drop([:as, :query])
      |> then(fn o -> if req.as, do: Keyword.put(o, :as, req.as), else: o end)
      |> then(fn o -> if req.query, do: Keyword.put(o, :query, req.query), else: o end)

    case req.method do
      "GET" -> get(req.url, opts)
      "POST" -> post(req.url, req.body, opts)
      "PATCH" -> patch(req.url, req.body, opts)
      "DELETE" -> delete(req.url, opts)
    end
  end

  @doc """
  Performs a GET request to the given path.

  ## Options

  * `:client` - A `%Req.Request{}` client
  * `:query` - An `%OData{}` struct or a map of query params
  * `:params` - Additional raw query params (map)
  * `:access_token` - Per-request access token (delegated permissions)
  * `:api_version` - Per-request API version override (`:v1` or `:beta`)
  * `:as` - Schema or view module to cast the response into
  """
  @spec get(String.t(), keyword()) :: {:ok, map()} | :ok | {:error, term()}
  def get(path, opts \\ []) do
    {as_module, opts} = Keyword.pop(opts, :as)
    opts = maybe_inject_select(opts, as_module)
    client = resolve_client(opts)

    req_opts =
      [url: resolve_url(path, opts), params: build_params(opts)]
      |> maybe_put_token(opts)

    client
    |> Req.get(req_opts)
    |> Response.normalize()
    |> maybe_cast(as_module)
  end

  @doc """
  Performs a POST request to the given path with the given body.
  """
  @spec post(String.t(), map() | nil, keyword()) :: {:ok, map()} | :ok | {:error, term()}
  def post(path, body, opts \\ []) do
    {as_module, opts} = Keyword.pop(opts, :as)
    client = resolve_client(opts)

    req_opts =
      [url: resolve_url(path, opts), params: build_params(opts)]
      |> maybe_put_token(opts)
      |> maybe_put_json(body)

    client
    |> Req.post(req_opts)
    |> Response.normalize()
    |> maybe_cast(as_module)
  end

  @doc """
  Performs a PATCH request to the given path with the given body.
  """
  @spec patch(String.t(), map(), keyword()) :: {:ok, map()} | :ok | {:error, term()}
  def patch(path, body, opts \\ []) do
    {as_module, opts} = Keyword.pop(opts, :as)
    client = resolve_client(opts)

    req_opts =
      [url: resolve_url(path, opts), json: body, params: build_params(opts)]
      |> maybe_put_token(opts)

    client
    |> Req.patch(req_opts)
    |> Response.normalize()
    |> maybe_cast(as_module)
  end

  @doc """
  Performs a DELETE request to the given path.
  """
  @spec delete(String.t(), keyword()) :: {:ok, map()} | :ok | {:error, term()}
  def delete(path, opts \\ []) do
    {as_module, opts} = Keyword.pop(opts, :as)
    client = resolve_client(opts)

    req_opts =
      [url: resolve_url(path, opts)]
      |> maybe_put_token(opts)

    client
    |> Req.delete(req_opts)
    |> Response.normalize()
    |> maybe_cast(as_module)
  end

  @doc false
  def maybe_inject_select(opts, nil), do: opts

  def maybe_inject_select(opts, as_module) do
    has_select? =
      case Keyword.get(opts, :query) do
        %OData{select: select} when not is_nil(select) -> true
        %{} = params -> Map.has_key?(params, "$select")
        _ -> false
      end

    if has_select? || !function_exported?(as_module, :__select__, 0) do
      opts
    else
      select_fields = as_module.__select__()

      case Keyword.get(opts, :query) do
        %OData{} = q ->
          Keyword.put(opts, :query, OData.select(q, select_fields))

        nil ->
          Keyword.put(opts, :query, OData.new() |> OData.select(select_fields))

        %{} = params ->
          Keyword.put(opts, :query, Map.put(params, "$select", Enum.join(select_fields, ",")))
      end
    end
  end

  @doc false
  def maybe_cast(result, nil), do: result

  def maybe_cast({:ok, %{"value" => items} = body}, as_module) when is_list(items) do
    cast_items = Enum.map(items, &as_module.from_map/1)
    {:ok, Map.put(body, "value", cast_items)}
  end

  def maybe_cast({:ok, body}, as_module) when is_map(body) do
    {:ok, as_module.from_map(body)}
  end

  def maybe_cast(other, _as_module), do: other

  defp maybe_put_token(req_opts, opts) do
    case Keyword.get(opts, :access_token) do
      nil -> req_opts
      token -> Keyword.put(req_opts, :access_token, token)
    end
  end

  defp maybe_put_json(req_opts, nil), do: req_opts
  defp maybe_put_json(req_opts, body), do: Keyword.put(req_opts, :json, body)

  defp resolve_url(path, opts) do
    case Keyword.get(opts, :api_version) do
      :beta -> Config.base_url_for(:beta) <> path
      :v1 -> Config.base_url_for(:v1) <> path
      nil -> path
    end
  end

  defp build_params(opts) do
    odata_params =
      case Keyword.get(opts, :query) do
        %OData{} = q -> OData.to_params(q)
        %{} = params -> params
        nil -> %{}
      end

    extra_params = Keyword.get(opts, :params, %{})
    Map.merge(odata_params, extra_params)
  end
end
