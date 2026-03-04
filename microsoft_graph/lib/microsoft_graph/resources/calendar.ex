defmodule MicrosoftGraph.Calendar do
  @moduledoc """
  Operations on calendar resources (`/users/{id}/events`, `/users/{id}/calendarView`, etc.).

  ## Examples

      {:ok, %{"value" => events}} = MicrosoftGraph.Calendar.list_events("user-id")

      {:ok, %{"value" => view}} = MicrosoftGraph.Calendar.calendar_view("user-id",
        start_date_time: "2024-01-01T00:00:00",
        end_date_time: "2024-01-31T23:59:59"
      )
  """

  alias MicrosoftGraph.Batch
  alias MicrosoftGraph.Delta
  alias MicrosoftGraph.Resource

  @doc """
  Lists events on a user's default calendar.
  """
  @spec list_events(String.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def list_events(user_id, opts \\ []) do
    Resource.get("/users/#{user_id}/events", opts)
  end

  @doc "Batch query variant of `list_events/2`."
  @spec list_events_query(String.t(), keyword()) :: Batch.Request.t()
  def list_events_query(user_id, opts \\ []), do: build_query("GET", "/users/#{user_id}/events", nil, opts)

  @doc """
  Gets a specific event.
  """
  @spec get_event(String.t(), String.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def get_event(user_id, event_id, opts \\ []) do
    Resource.get("/users/#{user_id}/events/#{event_id}", opts)
  end

  @doc "Batch query variant of `get_event/3`."
  @spec get_event_query(String.t(), String.t(), keyword()) :: Batch.Request.t()
  def get_event_query(user_id, event_id, opts \\ []) do
    build_query("GET", "/users/#{user_id}/events/#{event_id}", nil, opts)
  end

  @doc """
  Creates an event on a user's default calendar.
  """
  @spec create_event(String.t(), map(), keyword()) :: {:ok, map()} | {:error, term()}
  def create_event(user_id, attrs, opts \\ []) do
    Resource.post("/users/#{user_id}/events", attrs, opts)
  end

  @doc "Batch query variant of `create_event/3`."
  @spec create_event_query(String.t(), map(), keyword()) :: Batch.Request.t()
  def create_event_query(user_id, attrs, opts \\ []) do
    build_query("POST", "/users/#{user_id}/events", attrs, opts)
  end

  @doc """
  Updates an event.
  """
  @spec update_event(String.t(), String.t(), map(), keyword()) ::
          {:ok, map()} | :ok | {:error, term()}
  def update_event(user_id, event_id, attrs, opts \\ []) do
    Resource.patch("/users/#{user_id}/events/#{event_id}", attrs, opts)
  end

  @doc "Batch query variant of `update_event/4`."
  @spec update_event_query(String.t(), String.t(), map(), keyword()) :: Batch.Request.t()
  def update_event_query(user_id, event_id, attrs, opts \\ []) do
    build_query("PATCH", "/users/#{user_id}/events/#{event_id}", attrs, opts)
  end

  @doc """
  Deletes an event.
  """
  @spec delete_event(String.t(), String.t(), keyword()) :: :ok | {:error, term()}
  def delete_event(user_id, event_id, opts \\ []) do
    Resource.delete("/users/#{user_id}/events/#{event_id}", opts)
  end

  @doc "Batch query variant of `delete_event/3`."
  @spec delete_event_query(String.t(), String.t(), keyword()) :: Batch.Request.t()
  def delete_event_query(user_id, event_id, opts \\ []) do
    build_query("DELETE", "/users/#{user_id}/events/#{event_id}", nil, opts)
  end

  @doc """
  Gets the calendar view (events in a date range) for a user.

  ## Required Options

  * `:start_date_time` - ISO 8601 start datetime string
  * `:end_date_time` - ISO 8601 end datetime string

  ## Examples

      MicrosoftGraph.Calendar.calendar_view("user-id",
        start_date_time: "2024-01-01T00:00:00",
        end_date_time: "2024-01-31T23:59:59"
      )
  """
  @spec calendar_view(String.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def calendar_view(user_id, opts \\ []) do
    {start_dt, opts} = Keyword.pop!(opts, :start_date_time)
    {end_dt, opts} = Keyword.pop!(opts, :end_date_time)

    params = %{
      "startDateTime" => start_dt,
      "endDateTime" => end_dt
    }

    opts = Keyword.update(opts, :params, params, &Map.merge(&1, params))
    Resource.get("/users/#{user_id}/calendarView", opts)
  end

  @doc "Batch query variant of `calendar_view/2`. Embeds start/end datetimes in the URL."
  @spec calendar_view_query(String.t(), keyword()) :: Batch.Request.t()
  def calendar_view_query(user_id, opts \\ []) do
    {start_dt, opts} = Keyword.pop!(opts, :start_date_time)
    {end_dt, opts} = Keyword.pop!(opts, :end_date_time)
    {as, opts} = Keyword.pop(opts, :as)
    {query, _opts} = Keyword.pop(opts, :query)

    # Merge date params into the OData/query params
    date_params = %{"startDateTime" => start_dt, "endDateTime" => end_dt}

    query_params =
      case query do
        %MicrosoftGraph.OData{} = q -> Map.merge(MicrosoftGraph.OData.to_params(q), date_params)
        %{} = m -> Map.merge(m, date_params)
        nil -> date_params
      end

    %Batch.Request{method: "GET", url: "/users/#{user_id}/calendarView", query: query_params, as: as}
  end

  @doc """
  Lists a user's calendars.
  """
  @spec list_calendars(String.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def list_calendars(user_id, opts \\ []) do
    Resource.get("/users/#{user_id}/calendars", opts)
  end

  @doc "Batch query variant of `list_calendars/2`."
  @spec list_calendars_query(String.t(), keyword()) :: Batch.Request.t()
  def list_calendars_query(user_id, opts \\ []), do: build_query("GET", "/users/#{user_id}/calendars", nil, opts)

  @doc """
  Delta query for a user's calendar events. Returns event changes since the last sync.
  """
  @spec events_delta(String.t(), keyword()) :: {:ok, Delta.delta_page()} | {:error, term()}
  def events_delta(user_id, opts \\ []), do: Delta.query("/users/#{user_id}/events/delta", opts)

  @doc "Batch query variant of `events_delta/2`."
  @spec events_delta_query(String.t(), keyword()) :: Batch.Request.t()
  def events_delta_query(user_id, opts \\ []), do: build_query("GET", "/users/#{user_id}/events/delta", nil, opts)

  defp build_query(method, url, body, opts) do
    {as, opts} = Keyword.pop(opts, :as)
    {query, _opts} = Keyword.pop(opts, :query)
    %Batch.Request{method: method, url: url, body: body, query: query, as: as}
  end
end
