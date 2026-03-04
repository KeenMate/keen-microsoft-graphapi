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

  alias MicrosoftGraph.Resource

  @doc """
  Lists users in the organization.

  ## Options

  * `:client` - A configured Req client
  * `:query` - An `%OData{}` struct for query parameters
  """
  @spec list(keyword()) :: {:ok, map()} | {:error, term()}
  def list(opts \\ []) do
    Resource.get("/users", opts)
  end

  @doc """
  Gets a user by ID or userPrincipalName.
  """
  @spec get(String.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def get(user_id, opts \\ []) do
    Resource.get("/users/#{encode(user_id)}", opts)
  end

  @doc """
  Creates a new user.
  """
  @spec create(map(), keyword()) :: {:ok, map()} | {:error, term()}
  def create(attrs, opts \\ []) do
    Resource.post("/users", attrs, opts)
  end

  @doc """
  Updates a user.
  """
  @spec update(String.t(), map(), keyword()) :: {:ok, map()} | :ok | {:error, term()}
  def update(user_id, attrs, opts \\ []) do
    Resource.patch("/users/#{encode(user_id)}", attrs, opts)
  end

  @doc """
  Deletes a user.
  """
  @spec delete(String.t(), keyword()) :: :ok | {:error, term()}
  def delete(user_id, opts \\ []) do
    Resource.delete("/users/#{encode(user_id)}", opts)
  end

  @doc """
  Lists a user's direct reports.
  """
  @spec list_direct_reports(String.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def list_direct_reports(user_id, opts \\ []) do
    Resource.get("/users/#{encode(user_id)}/directReports", opts)
  end

  @doc """
  Lists groups and directory roles the user is a member of.
  """
  @spec list_member_of(String.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def list_member_of(user_id, opts \\ []) do
    Resource.get("/users/#{encode(user_id)}/memberOf", opts)
  end

  defp encode(id), do: URI.encode_www_form(id)
end
