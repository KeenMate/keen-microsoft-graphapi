defmodule MicrosoftGraph.Groups do
  @moduledoc """
  Operations on the `/groups` resource.

  ## Examples

      {:ok, %{"value" => groups}} = MicrosoftGraph.Groups.list()
      {:ok, group} = MicrosoftGraph.Groups.get("group-id")
      {:ok, %{"value" => members}} = MicrosoftGraph.Groups.list_members("group-id")
  """

  alias MicrosoftGraph.Resource

  @doc """
  Lists groups in the organization.
  """
  @spec list(keyword()) :: {:ok, map()} | {:error, term()}
  def list(opts \\ []) do
    Resource.get("/groups", opts)
  end

  @doc """
  Gets a group by ID.
  """
  @spec get(String.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def get(group_id, opts \\ []) do
    Resource.get("/groups/#{group_id}", opts)
  end

  @doc """
  Creates a new group.
  """
  @spec create(map(), keyword()) :: {:ok, map()} | {:error, term()}
  def create(attrs, opts \\ []) do
    Resource.post("/groups", attrs, opts)
  end

  @doc """
  Updates a group.
  """
  @spec update(String.t(), map(), keyword()) :: {:ok, map()} | :ok | {:error, term()}
  def update(group_id, attrs, opts \\ []) do
    Resource.patch("/groups/#{group_id}", attrs, opts)
  end

  @doc """
  Deletes a group.
  """
  @spec delete(String.t(), keyword()) :: :ok | {:error, term()}
  def delete(group_id, opts \\ []) do
    Resource.delete("/groups/#{group_id}", opts)
  end

  @doc """
  Lists members of a group.
  """
  @spec list_members(String.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def list_members(group_id, opts \\ []) do
    Resource.get("/groups/#{group_id}/members", opts)
  end

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

  @doc """
  Removes a member from a group.
  """
  @spec remove_member(String.t(), String.t(), keyword()) :: :ok | {:error, term()}
  def remove_member(group_id, member_id, opts \\ []) do
    Resource.delete("/groups/#{group_id}/members/#{member_id}/$ref", opts)
  end
end
