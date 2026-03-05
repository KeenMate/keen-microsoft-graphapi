defmodule GraphApi.Subscriptions do
  @moduledoc """
  Operations on the `/subscriptions` resource.

  Subscriptions allow your application to receive webhook notifications when
  data changes in Microsoft Graph. You create a subscription for a specific
  resource (e.g., users, messages, events) and Microsoft Graph sends POST
  requests to your notification URL when changes occur.

  ## Examples

      # Create a subscription
      {:ok, sub} = GraphApi.Subscriptions.create(%{
        "changeType" => "created,updated,deleted",
        "notificationUrl" => "https://example.com/webhook",
        "resource" => "users",
        "expirationDateTime" => "2025-04-01T00:00:00Z",
        "clientState" => "my-secret-state"
      })

      # List active subscriptions
      {:ok, %{"value" => subs}} = GraphApi.Subscriptions.list()

      # Renew before expiration
      {:ok, renewed} = GraphApi.Subscriptions.renew(sub["id"], %{
        "expirationDateTime" => "2025-05-01T00:00:00Z"
      })

      # Clean up
      :ok = GraphApi.Subscriptions.delete(sub["id"])
  """

  alias GraphApi.Batch
  alias GraphApi.Resource

  @doc """
  Lists active subscriptions.
  """
  @spec list(keyword()) :: {:ok, map()} | {:error, term()}
  def list(opts \\ []), do: Resource.execute(list_query(opts), opts)

  @doc "Batch query variant of `list/1`."
  @spec list_query(keyword()) :: Batch.Request.t()
  def list_query(opts \\ []), do: build_query("GET", "/subscriptions", nil, opts)

  @doc """
  Gets a subscription by ID.
  """
  @spec get(String.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def get(subscription_id, opts \\ []), do: Resource.execute(get_query(subscription_id, opts), opts)

  @doc "Batch query variant of `get/2`."
  @spec get_query(String.t(), keyword()) :: Batch.Request.t()
  def get_query(subscription_id, opts \\ []) do
    build_query("GET", "/subscriptions/#{subscription_id}", nil, opts)
  end

  @doc """
  Creates a new subscription.

  ## Required fields

  * `"changeType"` — Comma-separated: `"created"`, `"updated"`, `"deleted"`
  * `"notificationUrl"` — HTTPS endpoint that will receive notifications
  * `"resource"` — Resource path to watch (e.g., `"users"`, `"me/messages"`)
  * `"expirationDateTime"` — ISO 8601 datetime for subscription expiry

  ## Optional fields

  * `"clientState"` — Secret string included in each notification for validation
  * `"latestSupportedTlsVersion"` — Minimum TLS version
  """
  @spec create(map(), keyword()) :: {:ok, map()} | {:error, term()}
  def create(attrs, opts \\ []), do: Resource.execute(create_query(attrs, opts), opts)

  @doc "Batch query variant of `create/2`."
  @spec create_query(map(), keyword()) :: Batch.Request.t()
  def create_query(attrs, opts \\ []), do: build_query("POST", "/subscriptions", attrs, opts)

  @doc """
  Renews (updates) a subscription, typically to extend its expiration.

  ## Examples

      GraphApi.Subscriptions.renew("sub-id", %{
        "expirationDateTime" => "2025-05-01T00:00:00Z"
      })
  """
  @spec renew(String.t(), map(), keyword()) :: {:ok, map()} | :ok | {:error, term()}
  def renew(subscription_id, attrs, opts \\ []), do: Resource.execute(renew_query(subscription_id, attrs, opts), opts)

  @doc "Batch query variant of `renew/3`."
  @spec renew_query(String.t(), map(), keyword()) :: Batch.Request.t()
  def renew_query(subscription_id, attrs, opts \\ []) do
    build_query("PATCH", "/subscriptions/#{subscription_id}", attrs, opts)
  end

  @doc """
  Deletes a subscription.
  """
  @spec delete(String.t(), keyword()) :: :ok | {:error, term()}
  def delete(subscription_id, opts \\ []), do: Resource.execute(delete_query(subscription_id, opts), opts)

  @doc "Batch query variant of `delete/2`."
  @spec delete_query(String.t(), keyword()) :: Batch.Request.t()
  def delete_query(subscription_id, opts \\ []) do
    build_query("DELETE", "/subscriptions/#{subscription_id}", nil, opts)
  end

  defp build_query(method, url, body, opts) do
    {as, opts} = Keyword.pop(opts, :as)
    {query, _opts} = Keyword.pop(opts, :query)
    %Batch.Request{method: method, url: url, body: body, query: query, as: as}
  end
end
