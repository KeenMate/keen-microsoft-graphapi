defmodule DemoWeb.ExplorerLive do
  use Phoenix.LiveView

  alias DemoWeb.ExplorerLive.EndpointCatalog
  alias DemoWeb.ExplorerLive.ApiExecutor
  import DemoWeb.ExplorerLive.Components

  @impl true
  def mount(_params, session, socket) do
    grouped = EndpointCatalog.grouped()
    first_entry = grouped |> List.first() |> elem(1) |> List.first()

    # Pre-populate credentials from environment if available
    initial_params =
      %{}
      |> maybe_put_env("tenant_id", "AZURE_TENANT_ID")
      |> maybe_put_env("client_id", "AZURE_CLIENT_ID")
      |> maybe_put_env("client_secret", "AZURE_CLIENT_SECRET")

    # If a delegated access token exists in session, pre-fill it
    initial_params =
      case session["delegated_access_token"] do
        nil -> initial_params
        token -> Map.put(initial_params, "access_token", token)
      end

    {:ok,
     assign(socket,
       grouped_endpoints: grouped,
       selected_endpoint: first_entry,
       params: initial_params,
       delegated_signed_in: session["delegated_access_token"] != nil,
       result: nil,
       error: nil,
       metadata: nil,
       view_mode: "visual",
       loading: false
     )}
  end

  defp maybe_put_env(map, key, env_var) do
    case System.get_env(env_var) do
      nil -> map
      val -> Map.put(map, key, val)
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="explorer-grid">
      <.endpoint_nav
        grouped_endpoints={@grouped_endpoints}
        selected_endpoint={@selected_endpoint}
      />
      <.param_builder
        selected_endpoint={@selected_endpoint}
        params={@params}
        loading={@loading}
        delegated_signed_in={@delegated_signed_in}
      />
      <.result_display
        result={@result}
        error={@error}
        metadata={@metadata}
        view_mode={@view_mode}
        loading={@loading}
      />
    </div>
    """
  end

  @auth_keys ~w(tenant_id client_id client_secret access_token api_version advanced_query)

  @impl true
  def handle_event("select_endpoint", %{"id" => id}, socket) do
    entry = EndpointCatalog.find(String.to_existing_atom(id))

    # Preserve auth/global fields across endpoint switches
    kept = Map.take(socket.assigns.params, @auth_keys)

    # Pre-fill body template if available
    kept =
      if entry.body? && entry.body_template do
        Map.put(kept, "body", String.trim(entry.body_template))
      else
        kept
      end

    {:noreply,
     assign(socket,
       selected_endpoint: entry,
       params: kept,
       result: nil,
       error: nil,
       metadata: nil
     )}
  end

  def handle_event("update_params", params, socket) do
    # Remove Phoenix form metadata keys
    clean =
      params
      |> Map.drop(["_target", "_csrf_token"])

    # Merge with existing params to preserve values not in this change event
    merged = Map.merge(socket.assigns.params, clean)
    {:noreply, assign(socket, params: merged)}
  end


  def handle_event("execute", _params, socket) do
    entry = socket.assigns.selected_endpoint
    params = socket.assigns.params

    socket = assign(socket, loading: true, error: nil)

    {:noreply, start_async(socket, :api_call, fn -> ApiExecutor.execute(entry, params) end)}
  end

  def handle_event("load_next_page", _params, socket) do
    next_link = get_in(socket.assigns, [:metadata, "@odata.nextLink"])

    if next_link do
      params = socket.assigns.params
      socket = assign(socket, loading: true, error: nil)

      {:noreply,
       start_async(socket, :next_page, fn -> ApiExecutor.fetch_next_page(next_link, params) end)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("toggle_view", %{"mode" => mode}, socket) do
    {:noreply, assign(socket, view_mode: mode)}
  end

  @impl true
  def handle_async(:api_call, {:ok, {:ok, result, metadata}}, socket) do
    {:noreply, assign(socket, result: result, metadata: metadata, error: nil, loading: false)}
  end

  def handle_async(:api_call, {:ok, {:error, reason}}, socket) do
    {:noreply, assign(socket, error: reason, result: nil, metadata: nil, loading: false)}
  end

  def handle_async(:api_call, {:exit, reason}, socket) do
    {:noreply,
     assign(socket, error: "Process crashed: #{inspect(reason)}", result: nil, metadata: nil, loading: false)}
  end

  # Next page — append items to existing result
  def handle_async(:next_page, {:ok, {:ok, new_result, metadata}}, socket) do
    merged =
      case {socket.assigns.result, new_result} do
        {%{"value" => existing}, %{"value" => new_items}} when is_list(existing) and is_list(new_items) ->
          Map.put(new_result, "value", existing ++ new_items)

        _ ->
          new_result
      end

    {:noreply, assign(socket, result: merged, metadata: metadata, error: nil, loading: false)}
  end

  def handle_async(:next_page, {:ok, {:error, reason}}, socket) do
    {:noreply, assign(socket, error: reason, loading: false)}
  end

  def handle_async(:next_page, {:exit, reason}, socket) do
    {:noreply, assign(socket, error: "Process crashed: #{inspect(reason)}", loading: false)}
  end
end
