defmodule MicrosoftGraph.TokenStore do
  @moduledoc """
  GenServer that caches OAuth tokens keyed by `{tenant_id, client_id}`.

  Tokens are proactively refreshed before expiry. When a token is requested
  and found expired, it is refreshed synchronously before returning.

  This module is started automatically by `MicrosoftGraph.Application`.
  """

  use GenServer

  alias MicrosoftGraph.Auth
  alias MicrosoftGraph.Config

  @refresh_buffer_ms :timer.minutes(5)

  # Client API

  @doc """
  Starts the token store.
  """
  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, %{}, name: name)
  end

  @doc """
  Retrieves a valid access token for the given config.

  If a cached token exists and is still valid, it is returned immediately.
  If the token is expired or missing, a new token is acquired synchronously.
  """
  @spec get_token(Config.t(), GenServer.server()) ::
          {:ok, String.t()} | {:error, term()}
  def get_token(%Config{} = config, server \\ __MODULE__) do
    GenServer.call(server, {:get_token, config}, 30_000)
  end

  # Server callbacks

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_call({:get_token, config}, _from, state) do
    key = cache_key(config)

    case Map.get(state, key) do
      nil ->
        reply_with_acquired(config, key, state)

      token ->
        if Auth.token_expired?(token) do
          reply_with_acquired(config, key, state)
        else
          {:reply, {:ok, token.access_token}, state}
        end
    end
  end

  defp reply_with_acquired(config, key, state) do
    case acquire_and_cache(config, key, state) do
      {:ok, token, new_state} ->
        {:reply, {:ok, token.access_token}, new_state}

      {:error, error, _new_state} ->
        {:reply, {:error, error}, state}
    end
  end

  @impl true
  def handle_info({:refresh, config_attrs, key}, state) do
    config = struct!(Config, config_attrs)

    case Auth.acquire_token(config) do
      {:ok, token} ->
        schedule_refresh(config, token)
        {:noreply, Map.put(state, key, token)}

      {:error, _reason} ->
        # Retry in 30 seconds on failure
        Process.send_after(self(), {:refresh, config_attrs, key}, :timer.seconds(30))
        {:noreply, state}
    end
  end

  # Internal

  defp acquire_and_cache(config, key, state) do
    case Auth.acquire_token(config) do
      {:ok, token} ->
        schedule_refresh(config, token)
        {:ok, token, Map.put(state, key, token)}

      {:error, error} ->
        {:error, error, state}
    end
  end

  defp schedule_refresh(config, token) do
    refresh_in_ms = max((token.expires_in - 300) * 1000, @refresh_buffer_ms)
    config_attrs = Map.from_struct(config)
    key = cache_key(config)
    Process.send_after(self(), {:refresh, config_attrs, key}, refresh_in_ms)
  end

  defp cache_key(%Config{tenant_id: tid, client_id: cid}), do: {tid, cid}
end
