defmodule DemoWeb.ExplorerLive.ApiExecutor do
  @moduledoc """
  Translates form state into library calls and normalizes results.
  """

  alias DemoWeb.ExplorerLive.EndpointCatalog.Entry

  @doc """
  Executes the selected endpoint with the given form params.
  Returns `{:ok, result, metadata}` or `{:error, reason}`.
  """
  def execute(%Entry{} = entry, params) do
    try do
      client = build_client(params)
      odata = build_odata(params)
      opts = build_opts(client, odata, entry, params)
      args = build_args(entry, params)

      result = apply(entry.module, entry.function, args ++ [opts])

      case result do
        {:ok, body} ->
          {data, metadata} = normalize_result(body)
          {:ok, data, metadata}

        :ok ->
          {:ok, %{"status" => "Success (no content)"}, %{}}

        {:error, reason} ->
          {:error, reason}
      end
    rescue
      e ->
        {:error, Exception.message(e)}
    end
  end

  defp build_client(params) do
    api_version =
      case Map.get(params, "api_version", "v1") do
        "beta" -> :beta
        _ -> :v1
      end

    tenant_id = non_blank(params, "tenant_id")
    client_id = non_blank(params, "client_id")
    client_secret = non_blank(params, "client_secret")

    client_opts = [api_version: api_version]

    # Build explicit config from UI fields if all three are provided
    client_opts =
      if tenant_id && client_id && client_secret do
        config =
          MicrosoftGraph.Config.new!(
            tenant_id: tenant_id,
            client_id: client_id,
            client_secret: client_secret,
            api_version: api_version
          )

        Keyword.put(client_opts, :config, config)
      else
        client_opts
      end

    client = MicrosoftGraph.Client.new(client_opts)

    if Map.get(params, "advanced_query") == "true" do
      Req.Request.put_header(client, "consistencylevel", "eventual")
    else
      client
    end
  end

  defp non_blank(params, key) do
    case Map.get(params, key, "") do
      "" -> nil
      val -> String.trim(val)
    end
  end

  defp build_odata(params) do
    alias MicrosoftGraph.OData

    query = OData.new()

    query = maybe_set_select(query, params)
    query = maybe_set_filter(query, params)
    query = maybe_set_top(query, params)
    query = maybe_set_skip(query, params)
    query = maybe_set_orderby(query, params)
    query = maybe_set_expand(query, params)
    query = maybe_set_search(query, params)
    query = maybe_set_count(query, params)

    query
  end

  defp maybe_set_select(query, %{"odata_select" => val}) when val != "" do
    fields = val |> String.split(",") |> Enum.map(&String.trim/1)
    MicrosoftGraph.OData.select(query, fields)
  end

  defp maybe_set_select(query, _), do: query

  defp maybe_set_filter(query, %{"odata_filter" => val}) when val != "" do
    MicrosoftGraph.OData.filter(query, val)
  end

  defp maybe_set_filter(query, _), do: query

  defp maybe_set_top(query, %{"odata_top" => val}) when val != "" do
    case Integer.parse(val) do
      {n, _} when n > 0 -> MicrosoftGraph.OData.top(query, n)
      _ -> query
    end
  end

  defp maybe_set_top(query, _), do: query

  defp maybe_set_skip(query, %{"odata_skip" => val}) when val != "" do
    case Integer.parse(val) do
      {n, _} when n >= 0 -> MicrosoftGraph.OData.skip(query, n)
      _ -> query
    end
  end

  defp maybe_set_skip(query, _), do: query

  defp maybe_set_orderby(query, %{"odata_orderby" => val}) when val != "" do
    MicrosoftGraph.OData.orderby(query, val)
  end

  defp maybe_set_orderby(query, _), do: query

  defp maybe_set_expand(query, %{"odata_expand" => val}) when val != "" do
    fields = val |> String.split(",") |> Enum.map(&String.trim/1)
    MicrosoftGraph.OData.expand(query, fields)
  end

  defp maybe_set_expand(query, _), do: query

  defp maybe_set_search(query, %{"odata_search" => val}) when val != "" do
    MicrosoftGraph.OData.search(query, val)
  end

  defp maybe_set_search(query, _), do: query

  defp maybe_set_count(query, %{"advanced_query" => "true"}) do
    MicrosoftGraph.OData.count(query)
  end

  defp maybe_set_count(query, _), do: query

  defp build_opts(client, odata, entry, params) do
    opts = [client: client, query: odata]

    # Inject access token for delegated permissions
    opts =
      case non_blank(params, "access_token") do
        nil -> opts
        token -> Keyword.put(opts, :access_token, token)
      end

    # calendar_view needs start/end datetime as keyword opts
    opts =
      if entry.function == :calendar_view do
        start_dt = Map.get(params, "start_date_time", "")
        end_dt = Map.get(params, "end_date_time", "")

        opts
        |> Keyword.put(:start_date_time, start_dt)
        |> Keyword.put(:end_date_time, end_dt)
      else
        opts
      end

    # Cast response to schema struct when enabled
    opts =
      if entry.schema && Map.get(params, "cast_response") == "true" do
        Keyword.put(opts, :as, entry.schema)
      else
        opts
      end

    opts
  end

  defp build_args(entry, params) do
    path_args =
      Enum.map(entry.path_params, fn {key, _label} ->
        Map.get(params, key, "")
      end)

    # For functions that take a body argument (create, update, send_mail, etc.)
    body_arg =
      if entry.body? do
        body_str = Map.get(params, "body", "")

        case decode_body(entry, body_str) do
          {:ok, decoded} -> [decoded]
          :empty -> [%{}]
        end
      else
        []
      end

    path_args ++ body_arg
  end

  defp decode_body(%Entry{function: :upload_small}, body_str) do
    # upload_small takes raw binary content, not JSON
    if body_str == "", do: :empty, else: {:ok, body_str}
  end

  defp decode_body(_entry, "") do
    :empty
  end

  defp decode_body(_entry, body_str) do
    case Jason.decode(body_str) do
      {:ok, decoded} -> {:ok, decoded}
      {:error, _} -> {:ok, %{"_raw" => body_str}}
    end
  end

  @doc """
  Fetches the next page using an @odata.nextLink URL.
  Returns `{:ok, result, metadata}` or `{:error, reason}`.
  """
  def fetch_next_page(next_link, params) do
    try do
      client = build_client(params)

      client =
        case non_blank(params, "access_token") do
          nil -> client
          token -> Req.Request.put_option(client, :access_token, token)
        end

      case Req.get(client, url: next_link) do
        {:ok, %{status: status, body: body}} when status in 200..299 ->
          {data, metadata} = normalize_result(body)
          {:ok, data, metadata}

        {:ok, %{body: body}} ->
          {:error, body}

        {:error, reason} ->
          {:error, reason}
      end
    rescue
      e ->
        {:error, Exception.message(e)}
    end
  end

  defp normalize_result(body) when is_struct(body) do
    {body, %{}}
  end

  defp normalize_result(body) when is_map(body) do
    metadata =
      body
      |> Enum.filter(fn {k, _} -> is_binary(k) and String.starts_with?(k, "@odata") end)
      |> Map.new()

    {body, metadata}
  end

  defp normalize_result(body), do: {body, %{}}
end
