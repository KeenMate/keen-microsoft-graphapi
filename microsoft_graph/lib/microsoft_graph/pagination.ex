defmodule MicrosoftGraph.Pagination do
  @moduledoc """
  Stream-based pagination for Microsoft Graph API responses.

  Follows `@odata.nextLink` to lazily fetch subsequent pages.

  ## Examples

      {:ok, first_page} = MicrosoftGraph.Users.list(client: client)
      all_users = MicrosoftGraph.Pagination.stream(first_page, client: client)
        |> Enum.to_list()
  """

  alias MicrosoftGraph.Response

  @doc """
  Extracts page data from a Graph API response.

  Returns `{items, next_link}` where `items` is the list of items from `"value"`
  and `next_link` is the URL for the next page (or nil).

  Optionally accepts an `as:` module to cast each item.
  """
  @spec extract_page(map(), keyword()) :: {list(), String.t() | nil}
  def extract_page(body, opts \\ [])

  def extract_page(%{"value" => items} = body, opts) do
    next_link = Map.get(body, "@odata.nextLink")
    items = maybe_cast_items(items, Keyword.get(opts, :as))
    {items, next_link}
  end

  def extract_page(body, opts) when is_map(body) do
    item =
      case Keyword.get(opts, :as) do
        nil -> body
        mod -> mod.from_map(body)
      end

    {[item], nil}
  end

  @doc """
  Creates a lazy `Stream` that follows `@odata.nextLink` to yield all items.

  Takes the first page response body and options (must include `:client`).
  Optionally accepts `:as` to cast each item into a schema/view struct.

  ## Examples

      {:ok, page} = MicrosoftGraph.Users.list(client: client)
      stream = MicrosoftGraph.Pagination.stream(page, client: client)
      all = Enum.to_list(stream)

      # With schema casting
      stream = MicrosoftGraph.Pagination.stream(page, client: client, as: MicrosoftGraph.Schema.User)
  """
  @spec stream(map(), keyword()) :: Enumerable.t()
  def stream(first_page, opts \\ []) do
    client = Keyword.fetch!(opts, :client)
    as_module = Keyword.get(opts, :as)

    Stream.resource(
      fn -> {:page, first_page} end,
      fn
        {:page, page} ->
          emit_page(page, client, as_module)

        {:next, url, req_client} ->
          case fetch_next_page(url, req_client) do
            {:ok, page} -> emit_page(page, req_client, as_module)
            {:error, _reason} -> {:halt, :done}
          end

        :done ->
          {:halt, :done}
      end,
      fn _ -> :ok end
    )
  end

  defp emit_page(page, client, as_module) do
    {items, next_link} = extract_page(page, as: as_module)

    if next_link do
      {items, {:next, next_link, client}}
    else
      {items, :done}
    end
  end

  @doc """
  Collects all items from all pages into a single list.

  A convenience wrapper around `stream/2` that eagerly fetches all pages.
  """
  @spec collect_all(map(), keyword()) :: {:ok, list()} | {:error, term()}
  def collect_all(first_page, opts \\ []) do
    items = stream(first_page, opts) |> Enum.to_list()
    {:ok, items}
  end

  defp fetch_next_page(url, client) do
    client
    |> Req.get(url: url)
    |> Response.normalize()
  end

  defp maybe_cast_items(items, nil), do: items
  defp maybe_cast_items(items, mod), do: Enum.map(items, &mod.from_map/1)
end
