defmodule DemoWeb.ExplorerLive.Components do
  @moduledoc false
  use Phoenix.Component

  alias DemoWeb.ExplorerLive.EndpointCatalog.Entry

  # ── Left Column: Endpoint Navigator ──────────────────────────

  attr :grouped_endpoints, :list, required: true
  attr :selected_endpoint, Entry, default: nil

  def endpoint_nav(assigns) do
    ~H"""
    <div class="nav-column">
      <div class="nav-header">Endpoints</div>
      <div :for={{resource, entries} <- @grouped_endpoints}>
        <div class="nav-group-label">{resource}</div>
        <div
          :for={entry <- entries}
          class={"nav-item #{if @selected_endpoint && @selected_endpoint.id == entry.id, do: "active"}"}
          phx-click="select_endpoint"
          phx-value-id={entry.id}
        >
          <span class={"method-badge method-#{entry.method}"}>{method_label(entry.method)}</span>
          <span class="nav-item-label">{entry.label}</span>
        </div>
      </div>
    </div>
    """
  end

  defp method_label(:get), do: "GET"
  defp method_label(:post), do: "POST"
  defp method_label(:patch), do: "PATCH"
  defp method_label(:delete), do: "DEL"

  # ── Middle Column: Parameter Builder ─────────────────────────

  attr :selected_endpoint, Entry, default: nil
  attr :params, :map, required: true
  attr :loading, :boolean, default: false
  attr :delegated_signed_in, :boolean, default: false

  def param_builder(assigns) do
    ~H"""
    <div class="param-column">
      <div class="param-header">
        {if @selected_endpoint, do: "#{@selected_endpoint.resource}.#{@selected_endpoint.label}", else: "Parameters"}
      </div>

      <div :if={!@selected_endpoint} class="empty-state">
        Select an endpoint from the left panel to get started.
      </div>

      <div :if={@selected_endpoint && @selected_endpoint.description != ""} class="param-section">
        <div class="param-description">{@selected_endpoint.description}</div>
      </div>

      <form :if={@selected_endpoint} phx-change="update_params" phx-submit="execute">
        <%!-- Authentication --%>
        <div class="param-section">
          <div class="param-section-title">Authentication</div>
          <div class="param-field">
            <label for="auth-tenant-id">Tenant ID</label>
            <input
              type="text"
              id="auth-tenant-id"
              name="tenant_id"
              value={Map.get(@params, "tenant_id", "")}
              placeholder="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
              phx-debounce="300"
            />
          </div>
          <div class="param-field">
            <label for="auth-client-id">Client ID</label>
            <input
              type="text"
              id="auth-client-id"
              name="client_id"
              value={Map.get(@params, "client_id", "")}
              placeholder="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
              phx-debounce="300"
            />
          </div>
          <div class="param-field">
            <label for="auth-client-secret">Client Secret</label>
            <input
              type="password"
              id="auth-client-secret"
              name="client_secret"
              value={Map.get(@params, "client_secret", "")}
              placeholder="Client secret value"
              phx-debounce="300"
            />
          </div>
          <div class="param-field">
            <label for="auth-access-token">Access Token (optional, overrides client credentials)</label>
            <input
              type="password"
              id="auth-access-token"
              name="access_token"
              value={Map.get(@params, "access_token", "")}
              placeholder="Any valid Bearer token (user or app)"
              phx-debounce="300"
            />
          </div>
          <div class="param-field" style="display: flex; gap: 0.5rem; align-items: center;">
            <a href="/auth/login" class="btn btn-primary" style="text-decoration: none; padding: 0.4rem 0.8rem; background: #0078d4; color: #fff; border-radius: 4px; font-size: 0.85rem;">
              Sign in with Microsoft
            </a>
            <a :if={@delegated_signed_in} href="/auth/logout" style="font-size: 0.85rem; color: #666;">
              Sign out
            </a>
            <span :if={@delegated_signed_in} style="font-size: 0.8rem; color: #107c10;">
              Signed in (delegated token active)
            </span>
          </div>
        </div>

        <%!-- Path Parameters --%>
        <div :if={@selected_endpoint.path_params != []} class="param-section">
          <div class="param-section-title">Path Parameters</div>
          <div :for={{key, label} <- @selected_endpoint.path_params} class="param-field">
            <label for={"param-#{key}"}>{label}</label>
            <input
              type="text"
              id={"param-#{key}"}
              name={key}
              value={Map.get(@params, key, "")}
              placeholder={label}
              phx-debounce="300"
            />
          </div>
        </div>

        <%!-- Extra Parameters (e.g., calendar_view dates) --%>
        <div :if={@selected_endpoint.extra_params != []} class="param-section">
          <div class="param-section-title">Required Parameters</div>
          <div :for={{key, label} <- @selected_endpoint.extra_params} class="param-field">
            <label for={"param-#{key}"}>{label}</label>
            <input
              type="text"
              id={"param-#{key}"}
              name={key}
              value={Map.get(@params, key, "")}
              placeholder={label}
              phx-debounce="300"
            />
          </div>
        </div>

        <%!-- OData Query Parameters --%>
        <div class="param-section">
          <div class="param-section-title">OData Query</div>
          <div class="param-field">
            <label for="odata-select">$select</label>
            <input
              type="text"
              id="odata-select"
              name="odata_select"
              value={Map.get(@params, "odata_select", "")}
              placeholder="displayName,mail,id"
              phx-debounce="300"
            />
          </div>
          <div class="param-field">
            <label for="odata-filter">$filter</label>
            <input
              type="text"
              id="odata-filter"
              name="odata_filter"
              value={Map.get(@params, "odata_filter", "")}
              placeholder="startsWith(displayName, 'A')"
              phx-debounce="300"
            />
          </div>
          <div class="param-field">
            <label for="odata-top">$top</label>
            <input
              type="text"
              id="odata-top"
              name="odata_top"
              value={Map.get(@params, "odata_top", "")}
              placeholder="10"
              phx-debounce="300"
            />
          </div>
          <div class="param-field">
            <label for="odata-skip">$skip</label>
            <input
              type="text"
              id="odata-skip"
              name="odata_skip"
              value={Map.get(@params, "odata_skip", "")}
              placeholder="0"
              phx-debounce="300"
            />
          </div>
          <div class="param-field">
            <label for="odata-orderby">$orderby</label>
            <input
              type="text"
              id="odata-orderby"
              name="odata_orderby"
              value={Map.get(@params, "odata_orderby", "")}
              placeholder="displayName desc"
              phx-debounce="300"
            />
          </div>
          <div class="param-field">
            <label for="odata-expand">$expand</label>
            <input
              type="text"
              id="odata-expand"
              name="odata_expand"
              value={Map.get(@params, "odata_expand", "")}
              placeholder="manager,directReports"
              phx-debounce="300"
            />
          </div>
          <div class="param-field">
            <label for="odata-search">$search</label>
            <input
              type="text"
              id="odata-search"
              name="odata_search"
              value={Map.get(@params, "odata_search", "")}
              placeholder={~s("displayName:John")}
              phx-debounce="300"
            />
          </div>
        </div>

        <%!-- JSON Body --%>
        <div :if={@selected_endpoint.body?} class="param-section">
          <div class="param-section-title">
            Request Body {if @selected_endpoint.function == :upload_small, do: "(raw content)", else: "(JSON)"}
          </div>
          <div class="param-field">
            <textarea
              name="body"
              placeholder={@selected_endpoint.body_template || ~s|{\n  "key": "value"\n}|}
              phx-debounce="300"
            >{Map.get(@params, "body", "")}</textarea>
          </div>
        </div>

        <%!-- Options --%>
        <div class="param-section">
          <div class="param-section-title">Options</div>
          <div class="toggle-row">
            <div class="toggle-item">
              <label for="api-version">API Version</label>
              <select id="api-version" name="api_version">
                <option value="v1" selected={Map.get(@params, "api_version", "v1") == "v1"}>
                  v1.0
                </option>
                <option value="beta" selected={Map.get(@params, "api_version", "v1") == "beta"}>
                  beta
                </option>
              </select>
            </div>
          </div>
          <div :if={@selected_endpoint.schema} class="toggle-row" style="margin-top: 8px;">
            <div class="toggle-item">
              <input
                type="checkbox"
                id="cast-response"
                name="cast_response"
                value="true"
                checked={Map.get(@params, "cast_response") == "true"}
              />
              <label for="cast-response">Cast response to struct</label>
            </div>
          </div>
          <div :if={@selected_endpoint.schema} class="param-hint">
            Casts response items to <code>{inspect(@selected_endpoint.schema)}</code> typed structs.
          </div>
        </div>

        <%!-- Advanced Query (ConsistencyLevel + $count) --%>
        <div class="param-section">
          <div class="param-section-title">Advanced Query</div>
          <div class="toggle-row">
            <div class="toggle-item">
              <input
                type="checkbox"
                id="advanced-query"
                name="advanced_query"
                value="true"
                checked={Map.get(@params, "advanced_query") == "true"}
              />
              <label for="advanced-query">Enable advanced queries</label>
            </div>
          </div>
          <div class="param-hint">
            Sends <code>ConsistencyLevel: eventual</code> header and adds <code>$count=true</code>.
            Required for <code>$search</code>, <code>$count</code>, and some <code>$filter</code>/<code>$orderby</code> expressions.
          </div>
        </div>

        <%!-- Execute --%>
        <div class="param-section">
          <button type="submit" class="execute-btn" disabled={@loading}>
            {if @loading, do: "Executing...", else: "Execute"}
          </button>
        </div>
      </form>
    </div>
    """
  end

  # ── Right Column: Result Display ─────────────────────────────

  attr :result, :any, default: nil
  attr :error, :any, default: nil
  attr :metadata, :map, default: nil
  attr :view_mode, :string, default: "visual"
  attr :loading, :boolean, default: false

  def result_display(assigns) do
    ~H"""
    <div class="result-column">
      <div class="result-header">
        <span class="result-header-title">Results</span>
        <div :if={@result} class="tab-bar">
          <button
            type="button"
            class={"tab-btn #{if @view_mode == "visual", do: "active"}"}
            phx-click="toggle_view"
            phx-value-mode="visual"
          >
            Visual
          </button>
          <button
            type="button"
            class={"tab-btn #{if @view_mode == "raw", do: "active"}"}
            phx-click="toggle_view"
            phx-value-mode="raw"
          >
            Raw JSON
          </button>
        </div>
      </div>

      <%!-- Metadata Banner --%>
      <div :if={@metadata && map_size(@metadata) > 0} class="metadata-banner">
        <div :if={@metadata["@odata.count"]} class="metadata-item">
          <span class="metadata-label">@odata.count:</span>
          <span class="metadata-value">{@metadata["@odata.count"]}</span>
        </div>
        <div :if={@metadata["@odata.nextLink"]} class="metadata-item">
          <span class="metadata-label">@odata.nextLink:</span>
          <span class="metadata-value">{truncate(@metadata["@odata.nextLink"], 80)}</span>
        </div>
        <div :if={@metadata["@odata.context"]} class="metadata-item">
          <span class="metadata-label">@odata.context:</span>
          <span class="metadata-value">{truncate(@metadata["@odata.context"], 80)}</span>
        </div>
        <button
          :if={@metadata["@odata.nextLink"] && !@loading}
          type="button"
          class="next-page-btn"
          phx-click="load_next_page"
        >
          Load Next Page
        </button>
      </div>

      <div class="result-body">
        <%!-- Loading --%>
        <div :if={@loading} class="loading-spinner">
          <div class="spinner"></div>
          <span>Calling Microsoft Graph API...</span>
        </div>

        <%!-- Error --%>
        <div :if={@error && !@loading} class="error-box">
          <div class="error-box-title">Error</div>
          <pre>{format_error(@error)}</pre>
        </div>

        <%!-- Empty state --%>
        <div :if={!@result && !@error && !@loading} class="empty-state">
          Select an endpoint and click Execute to see results.
        </div>

        <%!-- Visual mode --%>
        <div :if={@result && !@loading && @view_mode == "visual"}>
          {render_visual(assigns)}
        </div>

        <%!-- Raw JSON mode --%>
        <div :if={@result && !@loading && @view_mode == "raw"}>
          <pre class="json-output">{format_json(@result)}</pre>
        </div>
      </div>
    </div>
    """
  end

  defp render_visual(assigns) do
    case assigns.result do
      %{"value" => items} when is_list(items) ->
        items = Enum.map(items, &struct_to_display_map/1)
        assigns = Phoenix.Component.assign(assigns, :items, items)

        ~H"""
        <div class="result-count">{length(@items)} item(s) returned</div>
        <div :if={@items == []} class="empty-state">No items in response.</div>
        <.result_table :if={@items != []} items={@items} />
        """

      single when is_struct(single) ->
        display = struct_to_display_map(single)
        assigns = Phoenix.Component.assign(assigns, :fields, map_to_fields(display))

        ~H"""
        <div class="result-cards">
          <div class="result-card">
            <div class="result-card-title">{display_title(@result)}</div>
            <div class="result-card-fields">
              <div :for={{key, val} <- @fields} class="result-card-key">{key}</div>
              <div :for={{_key, val} <- @fields} class="result-card-value">{format_value(val)}</div>
            </div>
          </div>
        </div>
        """

      single when is_map(single) ->
        assigns = Phoenix.Component.assign(assigns, :fields, map_to_fields(single))

        ~H"""
        <div class="result-cards">
          <div class="result-card">
            <div class="result-card-title">{display_title(@result)}</div>
            <div class="result-card-fields">
              <div :for={{key, val} <- @fields} class="result-card-key">{key}</div>
              <div :for={{_key, val} <- @fields} class="result-card-value">{format_value(val)}</div>
            </div>
          </div>
        </div>
        """

      other ->
        assigns = Phoenix.Component.assign(assigns, :text, inspect(other, pretty: true, limit: :infinity))

        ~H"""
        <pre class="json-output">{@text}</pre>
        """
    end
  end

  attr :items, :list, required: true

  defp result_table(assigns) do
    columns =
      assigns.items
      |> Enum.flat_map(&Map.keys/1)
      |> Enum.map(&to_string/1)
      |> Enum.uniq()
      |> Enum.reject(&String.starts_with?(&1, "@odata"))
      |> prioritize_columns()

    assigns = Phoenix.Component.assign(assigns, :columns, columns)

    ~H"""
    <div style="overflow-x: auto;">
      <table class="result-table">
        <thead>
          <tr>
            <th :for={col <- @columns}>{col}</th>
          </tr>
        </thead>
        <tbody>
          <tr :for={item <- @items}>
            <td :for={col <- @columns}>{format_value(Map.get(item, col))}</td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  defp prioritize_columns(columns) do
    priority = ~w(id displayName userPrincipalName mail name subject title description)

    {high, rest} =
      Enum.split_with(columns, &(&1 in priority))

    sorted_high =
      Enum.sort_by(high, fn col ->
        Enum.find_index(priority, &(&1 == col)) || 999
      end)

    sorted_high ++ Enum.sort(rest)
  end

  defp display_title(%{__struct__: mod} = struct) do
    short_name = mod |> Module.split() |> List.last()
    value = Map.get(struct, :display_name) || Map.get(struct, :name) || Map.get(struct, :subject) || Map.get(struct, :id)
    if value, do: "#{short_name}: #{value}", else: short_name
  end

  defp display_title(map) when is_map(map) do
    map["displayName"] || map["name"] || map["subject"] || map["id"] || "Result"
  end

  defp map_to_fields(map) do
    map
    |> Enum.reject(fn {k, _} -> String.starts_with?(k, "@odata") end)
    |> Enum.sort_by(fn {k, _} -> k end)
  end

  defp format_value(nil), do: "-"
  defp format_value(val) when is_binary(val), do: val
  defp format_value(val) when is_number(val), do: to_string(val)
  defp format_value(val) when is_boolean(val), do: to_string(val)

  defp format_value(val) when is_map(val) do
    Jason.encode!(val, pretty: false)
    |> truncate(100)
  end

  defp format_value(val) when is_list(val) do
    Jason.encode!(val, pretty: false)
    |> truncate(100)
  end

  defp format_value(val), do: inspect(val)

  defp format_json(data) do
    data
    |> deep_to_encodable()
    |> Jason.encode!(pretty: true)
  end

  defp struct_to_display_map(%{__struct__: _} = struct) do
    struct
    |> Map.from_struct()
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Enum.map(fn {k, v} -> {to_string(k), v} end)
    |> Map.new()
  end

  defp struct_to_display_map(map) when is_map(map), do: map

  defp deep_to_encodable(%{__struct__: _} = struct) do
    struct
    |> Map.from_struct()
    |> deep_to_encodable()
  end

  defp deep_to_encodable(map) when is_map(map) do
    Map.new(map, fn {k, v} -> {k, deep_to_encodable(v)} end)
  end

  defp deep_to_encodable(list) when is_list(list) do
    Enum.map(list, &deep_to_encodable/1)
  end

  defp deep_to_encodable(other), do: other

  defp format_error(%{message: msg}), do: msg
  defp format_error(%{"error" => %{"message" => msg, "code" => code}}), do: "#{code}: #{msg}"
  defp format_error(err) when is_binary(err), do: err
  defp format_error(err), do: inspect(err, pretty: true)

  defp truncate(str, max) when byte_size(str) > max do
    String.slice(str, 0, max) <> "..."
  end

  defp truncate(str, _max), do: str
end
