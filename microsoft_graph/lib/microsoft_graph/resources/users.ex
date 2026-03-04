defmodule MicrosoftGraph.Users do
  @moduledoc """
  Operations on the `/users` resource.

  ## Examples

      # List users
      {:ok, %{"value" => users}} = MicrosoftGraph.Users.list()

      # Get a specific user
      {:ok, user} = MicrosoftGraph.Users.get("user@contoso.com")

      # With OData query
      alias MicrosoftGraph.OData
      query = OData.new() |> OData.select(["displayName", "mail"]) |> OData.top(10)
      {:ok, response} = MicrosoftGraph.Users.list(query: query)

      # Multi-tenant
      client = MicrosoftGraph.Client.new(config: config)
      {:ok, users} = MicrosoftGraph.Users.list(client: client)
  """

  alias MicrosoftGraph.Batch
  alias MicrosoftGraph.Delta
  alias MicrosoftGraph.Resource

  @doc """
  Lists users in the organization.

  ## Options

  * `:client` - A configured Req client
  * `:query` - An `%OData{}` struct for query parameters
  * `:as` - Schema or view module to cast each result
  """
  @spec list(keyword()) :: {:ok, map()} | {:error, term()}
  def list(opts \\ []) do
    Resource.get("/users", opts)
  end

  @doc "Batch query variant of `list/1`. Returns a `%Batch.Request{}`."
  @spec list_query(keyword()) :: Batch.Request.t()
  def list_query(opts \\ []) do
    build_query("GET", "/users", nil, opts)
  end

  @doc """
  Gets a user by ID or userPrincipalName.
  """
  @spec get(String.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def get(user_id, opts \\ []) do
    Resource.get("/users/#{encode(user_id)}", opts)
  end

  @doc "Batch query variant of `get/2`. Returns a `%Batch.Request{}`."
  @spec get_query(String.t(), keyword()) :: Batch.Request.t()
  def get_query(user_id, opts \\ []) do
    build_query("GET", "/users/#{encode(user_id)}", nil, opts)
  end

  @doc """
  Creates a new user.
  """
  @spec create(map(), keyword()) :: {:ok, map()} | {:error, term()}
  def create(attrs, opts \\ []) do
    Resource.post("/users", attrs, opts)
  end

  @doc "Batch query variant of `create/2`. Returns a `%Batch.Request{}`."
  @spec create_query(map(), keyword()) :: Batch.Request.t()
  def create_query(attrs, opts \\ []) do
    build_query("POST", "/users", attrs, opts)
  end

  @doc """
  Updates a user.
  """
  @spec update(String.t(), map(), keyword()) :: {:ok, map()} | :ok | {:error, term()}
  def update(user_id, attrs, opts \\ []) do
    Resource.patch("/users/#{encode(user_id)}", attrs, opts)
  end

  @doc "Batch query variant of `update/3`. Returns a `%Batch.Request{}`."
  @spec update_query(String.t(), map(), keyword()) :: Batch.Request.t()
  def update_query(user_id, attrs, opts \\ []) do
    build_query("PATCH", "/users/#{encode(user_id)}", attrs, opts)
  end

  @doc """
  Deletes a user.
  """
  @spec delete(String.t(), keyword()) :: :ok | {:error, term()}
  def delete(user_id, opts \\ []) do
    Resource.delete("/users/#{encode(user_id)}", opts)
  end

  @doc "Batch query variant of `delete/2`. Returns a `%Batch.Request{}`."
  @spec delete_query(String.t(), keyword()) :: Batch.Request.t()
  def delete_query(user_id, opts \\ []) do
    build_query("DELETE", "/users/#{encode(user_id)}", nil, opts)
  end

  @doc """
  Lists a user's direct reports.
  """
  @spec list_direct_reports(String.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def list_direct_reports(user_id, opts \\ []) do
    Resource.get("/users/#{encode(user_id)}/directReports", opts)
  end

  @doc "Batch query variant of `list_direct_reports/2`. Returns a `%Batch.Request{}`."
  @spec list_direct_reports_query(String.t(), keyword()) :: Batch.Request.t()
  def list_direct_reports_query(user_id, opts \\ []) do
    build_query("GET", "/users/#{encode(user_id)}/directReports", nil, opts)
  end

  @doc """
  Lists groups and directory roles the user is a member of.
  """
  @spec list_member_of(String.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def list_member_of(user_id, opts \\ []) do
    Resource.get("/users/#{encode(user_id)}/memberOf", opts)
  end

  @doc "Batch query variant of `list_member_of/2`. Returns a `%Batch.Request{}`."
  @spec list_member_of_query(String.t(), keyword()) :: Batch.Request.t()
  def list_member_of_query(user_id, opts \\ []) do
    build_query("GET", "/users/#{encode(user_id)}/memberOf", nil, opts)
  end

  @doc """
  Delta query for users. Returns changes since the last sync.

  See `MicrosoftGraph.Delta` for details.
  """
  @spec delta(keyword()) :: {:ok, Delta.delta_page()} | {:error, term()}
  def delta(opts \\ []), do: Delta.query("/users/delta", opts)

  @doc "Batch query variant of `delta/1`."
  @spec delta_query(keyword()) :: Batch.Request.t()
  def delta_query(opts \\ []), do: build_query("GET", "/users/delta", nil, opts)

  defp encode(id), do: URI.encode_www_form(id)

  defp build_query(method, url, body, opts) do
    {as, opts} = Keyword.pop(opts, :as)
    {query, _opts} = Keyword.pop(opts, :query)

    %Batch.Request{method: method, url: url, body: body, query: query, as: as}
  end
end
