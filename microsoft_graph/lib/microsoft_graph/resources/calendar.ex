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

  alias MicrosoftGraph.Resource

  @doc """
  Lists events on a user's default calendar.
  """
  @spec list_events(String.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def list_events(user_id, opts \\ []) do
    Resource.get("/users/#{user_id}/events", opts)
  end

  @doc """
  Gets a specific event.
  """
  @spec get_event(String.t(), String.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def get_event(user_id, event_id, opts \\ []) do
    Resource.get("/users/#{user_id}/events/#{event_id}", opts)
  end

  @doc """
  Creates an event on a user's default calendar.
  """
  @spec create_event(String.t(), map(), keyword()) :: {:ok, map()} | {:error, term()}
  def create_event(user_id, attrs, opts \\ []) do
    Resource.post("/users/#{user_id}/events", attrs, opts)
  end

  @doc """
  Updates an event.
  """
  @spec update_event(String.t(), String.t(), map(), keyword()) ::
          {:ok, map()} | :ok | {:error, term()}
  def update_event(user_id, event_id, attrs, opts \\ []) do
    Resource.patch("/users/#{user_id}/events/#{event_id}", attrs, opts)
  end

  @doc """
  Deletes an event.
  """
  @spec delete_event(String.t(), String.t(), keyword()) :: :ok | {:error, term()}
  def delete_event(user_id, event_id, opts \\ []) do
    Resource.delete("/users/#{user_id}/events/#{event_id}", opts)
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

  @doc """
  Lists a user's calendars.
  """
  @spec list_calendars(String.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def list_calendars(user_id, opts \\ []) do
    Resource.get("/users/#{user_id}/calendars", opts)
  end
end
