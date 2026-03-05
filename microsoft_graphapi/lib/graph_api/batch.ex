defmodule GraphApi.Batch do
  @moduledoc """
  JSON batch requests for Microsoft Graph API.

  Allows sending up to 20 requests in a single HTTP call via `POST /$batch`.
  Build batch requests using `_query` functions from resource modules.

  ## Examples

      alias GraphApi.{Batch, OData, Users, Groups}
      alias GraphApi.Schema.{User, Group}

      query = OData.new() |> OData.select(["id", "displayName"]) |> OData.top(5)

      {:ok, responses} =
        Batch.new()
        |> Batch.add("1", Users.list_query(query: query, as: User))
        |> Batch.add("2", Groups.get_query("group-id", as: Group))
        |> Batch.add("3", Users.create_query(%{"displayName" => "New"}, as: User))
        |> Batch.execute(client: client)

      %{status: 200, body: %{"value" => users}} = Batch.get(responses, "1")
  """

  alias GraphApi.OData
  alias GraphApi.Resource

  defmodule Request do
    @moduledoc """
    A deferred Graph API request, created by `_query` functions on resource modules.
    """
    defstruct [:method, :url, :body, :headers, :as, query: nil, depends_on: nil]

    @type t :: %__MODULE__{
            method: String.t(),
            url: String.t(),
            body: map() | binary() | nil,
            headers: map() | nil,
            query: OData.t() | map() | nil,
            as: module() | nil,
            depends_on: [String.t()] | nil
          }
  end

  defmodule Entry do
    @moduledoc false
    defstruct [:id, :request, depends_on: nil]
  end

  @type t :: %__MODULE__{entries: [Entry.t()]}
  defstruct entries: []

  @max_requests 20

  @doc """
  Creates a new empty batch.
  """
  @spec new() :: t()
  def new, do: %__MODULE__{}

  @doc """
  Adds a request to the batch with the given ID.

  ## Options

  * `:depends_on` - List of request IDs that must complete before this one.

  ## Examples

      Batch.new()
      |> Batch.add("1", Users.list_query(as: User))
      |> Batch.add("2", Users.create_query(attrs, as: User), depends_on: ["1"])
  """
  @spec add(t(), String.t(), Request.t(), keyword()) :: t()
  def add(%__MODULE__{} = batch, id, %Request{} = request, add_opts \\ []) do
    depends_on = Keyword.get(add_opts, :depends_on) || request.depends_on
    entry = %Entry{id: id, request: request, depends_on: depends_on}
    %{batch | entries: batch.entries ++ [entry]}
  end

  @doc """
  Executes the batch, sending all requests in a single `POST /$batch` call.

  Returns `{:ok, [response]}` where each response has `:id`, `:status`, `:headers`, and `:body`.
  Response bodies are automatically cast using the `:as` schema specified on each request.

  ## Options

  Same as other resource functions: `:client`, `:access_token`, `:api_version`
  """
  @spec execute(t(), keyword()) :: {:ok, [map()]} | {:error, term()}
  def execute(%__MODULE__{entries: entries}, opts \\ []) do
    count = length(entries)

    cond do
      count == 0 ->
        {:ok, []}

      count > @max_requests ->
        {:error, "Batch limited to #{@max_requests} requests, got #{count}"}

      true ->
        as_map = Map.new(entries, fn %Entry{id: id, request: req} -> {id, req.as} end)

        batch_body = %{
          "requests" => Enum.map(entries, &serialize_entry/1)
        }

        case Resource.post("/$batch", batch_body, opts) do
          {:ok, %{"responses" => responses}} ->
            cast_responses =
              responses
              |> Enum.sort_by(& &1["id"])
              |> Enum.map(&normalize_response(&1, as_map))

            {:ok, cast_responses}

          {:ok, other} ->
            {:error, "Unexpected batch response: #{inspect(other)}"}

          {:error, _} = err ->
            err
        end
    end
  end

  @doc """
  Finds a response by its request ID.

  ## Examples

      {:ok, responses} = Batch.execute(batch, client: client)
      %{status: 200, body: user} = Batch.get(responses, "1")
  """
  @spec get([map()], String.t()) :: map() | nil
  def get(responses, id) when is_list(responses) do
    Enum.find(responses, &(&1.id == id))
  end

  # -- Serialization --

  defp serialize_entry(%Entry{id: id, request: req, depends_on: depends_on}) do
    url = build_url(req.url, req.query)

    entry = %{"id" => id, "method" => req.method, "url" => url}

    entry =
      if req.body do
        Map.put(entry, "body", req.body)
      else
        entry
      end

    entry =
      if req.headers do
        Map.put(entry, "headers", req.headers)
      else
        entry
      end

    entry =
      if depends_on do
        Map.put(entry, "dependsOn", depends_on)
      else
        entry
      end

    entry
  end

  defp build_url(url, nil), do: url

  defp build_url(url, %OData{} = query) do
    params = OData.to_params(query)
    build_url(url, params)
  end

  defp build_url(url, params) when is_map(params) and map_size(params) == 0, do: url

  defp build_url(url, params) when is_map(params) do
    qs =
      params
      |> Enum.sort_by(fn {k, _} -> k end)
      |> Enum.map(fn {k, v} -> "#{URI.encode_www_form(k)}=#{URI.encode_www_form(to_string(v))}" end)
      |> Enum.join("&")

    "#{url}?#{qs}"
  end

  # -- Response normalization --

  defp normalize_response(resp, as_map) do
    id = resp["id"]
    status = resp["status"]
    headers = resp["headers"] || %{}
    body = resp["body"]
    as_module = Map.get(as_map, id)

    body = maybe_cast_body(body, status, as_module)

    %{id: id, status: status, headers: headers, body: body}
  end

  defp maybe_cast_body(body, status, as_module)
       when is_map(body) and status >= 200 and status < 300 and not is_nil(as_module) do
    Resource.maybe_cast({:ok, body}, as_module)
    |> case do
      {:ok, cast} -> cast
      _ -> body
    end
  end

  defp maybe_cast_body(body, _status, _as_module), do: body
end
