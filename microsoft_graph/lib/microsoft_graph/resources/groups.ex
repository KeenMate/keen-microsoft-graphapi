defmodule MicrosoftGraph.Groups do
  @moduledoc """
  Operations on the `/groups` resource.

  ## Examples

      {:ok, %{"value" => groups}} = MicrosoftGraph.Groups.list()
      {:ok, group} = MicrosoftGraph.Groups.get("group-id")
      {:ok, %{"value" => members}} = MicrosoftGraph.Groups.list_members("group-id")
  """

  alias MicrosoftGraph.Batch
  alias MicrosoftGraph.Delta
  alias MicrosoftGraph.Resource

  @doc """
  Lists groups in the organization.
  """
  @spec list(keyword()) :: {:ok, map()} | {:error, term()}
  def list(opts \\ []) do
    Resource.get("/groups", opts)
  end

  @doc "Batch query variant of `list/1`."
  @spec list_query(keyword()) :: Batch.Request.t()
  def list_query(opts \\ []), do: build_query("GET", "/groups", nil, opts)

  @doc """
  Gets a group by ID.
  """
  @spec get(String.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def get(group_id, opts \\ []) do
    Resource.get("/groups/#{group_id}", opts)
  end

  @doc "Batch query variant of `get/2`."
  @spec get_query(String.t(), keyword()) :: Batch.Request.t()
  def get_query(group_id, opts \\ []), do: build_query("GET", "/groups/#{group_id}", nil, opts)

  @doc """
  Creates a new group.
  """
  @spec create(map(), keyword()) :: {:ok, map()} | {:error, term()}
  def create(attrs, opts \\ []) do
    Resource.post("/groups", attrs, opts)
  end

  @doc "Batch query variant of `create/2`."
  @spec create_query(map(), keyword()) :: Batch.Request.t()
  def create_query(attrs, opts \\ []), do: build_query("POST", "/groups", attrs, opts)

  @doc """
  Updates a group.
  """
  @spec update(String.t(), map(), keyword()) :: {:ok, map()} | :ok | {:error, term()}
  def update(group_id, attrs, opts \\ []) do
    Resource.patch("/groups/#{group_id}", attrs, opts)
  end

  @doc "Batch query variant of `update/3`."
  @spec update_query(String.t(), map(), keyword()) :: Batch.Request.t()
  def update_query(group_id, attrs, opts \\ []), do: build_query("PATCH", "/groups/#{group_id}", attrs, opts)

  @doc """
  Deletes a group.
  """
  @spec delete(String.t(), keyword()) :: :ok | {:error, term()}
  def delete(group_id, opts \\ []) do
    Resource.delete("/groups/#{group_id}", opts)
  end

  @doc "Batch query variant of `delete/2`."
  @spec delete_query(String.t(), keyword()) :: Batch.Request.t()
  def delete_query(group_id, opts \\ []), do: build_query("DELETE", "/groups/#{group_id}", nil, opts)

  @doc """
  Lists members of a group.
  """
  @spec list_members(String.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def list_members(group_id, opts \\ []) do
    Resource.get("/groups/#{group_id}/members", opts)
  end

  @doc "Batch query variant of `list_members/2`."
  @spec list_members_query(String.t(), keyword()) :: Batch.Request.t()
  def list_members_query(group_id, opts \\ []), do: build_query("GET", "/groups/#{group_id}/members", nil, opts)

  @doc """
  Adds a member to a group.

  The `member_id` should be the directory object ID of the user or service principal.
  """
  @spec add_member(String.t(), String.t(), keyword()) :: :ok | {:error, term()}
  def add_member(group_id, member_id, opts \\ []) do
    body = %{
      "@odata.id" => "https://graph.microsoft.com/v1.0/directoryObjects/#{member_id}"
    }

    Resource.post("/groups/#{group_id}/members/$ref", body, opts)
  end

  @doc "Batch query variant of `add_member/3`."
  @spec add_member_query(String.t(), String.t(), keyword()) :: Batch.Request.t()
  def add_member_query(group_id, member_id, opts \\ []) do
    body = %{"@odata.id" => "https://graph.microsoft.com/v1.0/directoryObjects/#{member_id}"}
    build_query("POST", "/groups/#{group_id}/members/$ref", body, opts)
  end

  @doc """
  Removes a member from a group.
  """
  @spec remove_member(String.t(), String.t(), keyword()) :: :ok | {:error, term()}
  def remove_member(group_id, member_id, opts \\ []) do
    Resource.delete("/groups/#{group_id}/members/#{member_id}/$ref", opts)
  end

  @doc "Batch query variant of `remove_member/3`."
  @spec remove_member_query(String.t(), String.t(), keyword()) :: Batch.Request.t()
  def remove_member_query(group_id, member_id, opts \\ []) do
    build_query("DELETE", "/groups/#{group_id}/members/#{member_id}/$ref", nil, opts)
  end

  @doc """
  Delta query for groups. Returns changes since the last sync.

  See `MicrosoftGraph.Delta` for details.
  """
  @spec delta(keyword()) :: {:ok, Delta.delta_page()} | {:error, term()}
  def delta(opts \\ []), do: Delta.query("/groups/delta", opts)

  @doc "Batch query variant of `delta/1`."
  @spec delta_query(keyword()) :: Batch.Request.t()
  def delta_query(opts \\ []), do: build_query("GET", "/groups/delta", nil, opts)

  @doc """
  Delta query for group membership. Returns member changes since the last sync.
  """
  @spec members_delta(String.t(), keyword()) :: {:ok, Delta.delta_page()} | {:error, term()}
  def members_delta(group_id, opts \\ []), do: Delta.query("/groups/#{group_id}/members/delta", opts)

  @doc "Batch query variant of `members_delta/2`."
  @spec members_delta_query(String.t(), keyword()) :: Batch.Request.t()
  def members_delta_query(group_id, opts \\ []), do: build_query("GET", "/groups/#{group_id}/members/delta", nil, opts)

  defp build_query(method, url, body, opts) do
    {as, opts} = Keyword.pop(opts, :as)
    {query, _opts} = Keyword.pop(opts, :query)
    %Batch.Request{method: method, url: url, body: body, query: query, as: as}
  end
end
