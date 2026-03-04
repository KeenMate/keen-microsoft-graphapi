defmodule MicrosoftGraph.Delta do
  @moduledoc """
  Delta query support for tracking incremental changes.

  Delta queries return changes since the last sync point. The first call returns
  the full dataset plus a `deltaLink`. Subsequent calls with the `deltaLink`
  return only items that changed (created, updated, or deleted).

  ## How it works

  1. Initial sync: `Delta.query("/users/delta", client: client)`
     Returns all current items + a `delta_link` for future syncs.

  2. Incremental sync: `Delta.query(delta_link, client: client)`
     Returns only changes since the last sync. Deleted items have an `@removed` property.

  ## Examples

      # Initial sync
      {:ok, page} = Delta.query("/users/delta", client: client)
      # page.items => [all current users]
      # page.delta_link => "https://graph...?$deltatoken=..."

      # Store delta_link, then later:
      {:ok, changes} = Delta.query(page.delta_link, client: client)
      # changes.items => only what changed

      # Collect all pages at once
      {:ok, result} = Delta.collect_all("/users/delta", client: client)

  ## Supported resources

  - `/users/delta`
  - `/groups/delta`
  - `/groups/{id}/members/delta`
  - `/me/messages/delta` or `/users/{id}/messages/delta`
  - `/me/mailFolders/{id}/messages/delta`
  - `/me/events/delta` or `/users/{id}/events/delta`
  - `/drives/{id}/root/delta`
  """

  alias MicrosoftGraph.Resource
  alias MicrosoftGraph.Response

  @type delta_page :: %{
          items: [map()],
          delta_link: String.t() | nil,
          next_link: String.t() | nil
        }

  @doc """
  Performs a delta query and returns a single page of results.

  Accepts either a relative path (e.g., `"/users/delta"`) for initial sync,
  or a full deltaLink/nextLink URL for subsequent pages.

  ## Options

  Same as other resource functions: `:client`, `:query`, `:access_token`, `:api_version`, `:as`

  ## Examples

      # Initial sync
      {:ok, page} = Delta.query("/users/delta", client: client)

      # Follow deltaLink for changes
      {:ok, changes} = Delta.query(page.delta_link, client: client)

      # With OData query
      query = OData.new() |> OData.select(["id", "displayName"]) |> OData.top(100)
      {:ok, page} = Delta.query("/users/delta", client: client, query: query)
  """
  @spec query(String.t(), keyword()) :: {:ok, delta_page()} | {:error, term()}
  def query(path_or_link, opts \\ []) do
    {as_module, opts} = Keyword.pop(opts, :as)

    result =
      if full_url?(path_or_link) do
        fetch_url(path_or_link, opts)
      else
        Resource.get(path_or_link, opts)
      end

    case result do
      {:ok, body} when is_map(body) ->
        {:ok, extract_delta_page(body, as_module)}

      {:error, _} = err ->
        err
    end
  end

  @doc """
  Collects all pages of a delta query into a single result.

  Follows `@odata.nextLink` pages until a `deltaLink` is received.
  Returns all accumulated items plus the final `delta_link`.

  ## Examples

      {:ok, result} = Delta.collect_all("/users/delta", client: client)
      # result.items => all items across all pages
      # result.delta_link => "https://...?$deltatoken=..."
  """
  @spec collect_all(String.t(), keyword()) :: {:ok, delta_page()} | {:error, term()}
  def collect_all(path_or_link, opts \\ []) do
    case query(path_or_link, opts) do
      {:ok, first_page} ->
        collect_pages(first_page, opts)

      {:error, _} = err ->
        err
    end
  end

  @doc """
  Creates a lazy `Stream` that yields items from all pages of a delta query.

  The stream follows `@odata.nextLink` pages automatically. After the stream
  is consumed, use `collect_all/2` if you need the `delta_link`.

  ## Examples

      {:ok, first_page} = Delta.query("/users/delta", client: client)

      first_page
      |> Delta.stream(client: client)
      |> Stream.filter(fn item -> item["@removed"] == nil end)
      |> Enum.to_list()
  """
  @spec stream(delta_page(), keyword()) :: Enumerable.t()
  def stream(%{} = first_page, opts \\ []) do
    Stream.resource(
      fn -> {:page, first_page} end,
      fn
        {:page, %{items: items, next_link: next_link}} when not is_nil(next_link) ->
          {items, {:next, next_link}}

        {:page, %{items: items}} ->
          {items, :done}

        {:next, url} ->
          case query(url, opts) do
            {:ok, page} ->
              if page.next_link do
                {page.items, {:next, page.next_link}}
              else
                {page.items, :done}
              end

            {:error, _reason} ->
              {:halt, :done}
          end

        :done ->
          {:halt, :done}
      end,
      fn _ -> :ok end
    )
  end

  # -- Internal --

  defp extract_delta_page(body, as_module) do
    items = Map.get(body, "value", [])
    items = maybe_cast_items(items, as_module)

    %{
      items: items,
      delta_link: Map.get(body, "@odata.deltaLink"),
      next_link: Map.get(body, "@odata.nextLink")
    }
  end

  defp maybe_cast_items(items, nil), do: items

  defp maybe_cast_items(items, as_module) do
    Enum.map(items, fn item ->
      if Map.has_key?(item, "@removed") do
        # Don't cast removed items — they only have id and @removed
        item
      else
        as_module.from_map(item)
      end
    end)
  end

  defp collect_pages(%{next_link: nil} = page, _opts) do
    {:ok, page}
  end

  defp collect_pages(%{items: items, next_link: next_link}, opts) do
    case query(next_link, opts) do
      {:ok, next_page} ->
        merged = %{next_page | items: items ++ next_page.items}
        collect_pages(merged, opts)

      {:error, _} = err ->
        err
    end
  end

  defp fetch_url(url, opts) do
    client = Resource.resolve_client(opts)

    req_opts = [url: url]

    req_opts =
      case Keyword.get(opts, :access_token) do
        nil -> req_opts
        token -> Keyword.put(req_opts, :access_token, token)
      end

    client
    |> Req.get(req_opts)
    |> Response.normalize()
  end

  defp full_url?(str), do: String.starts_with?(str, "http")
end
