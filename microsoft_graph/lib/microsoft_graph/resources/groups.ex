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
  def list(opts \\ []), do: Resource.execute(list_query(opts), opts)

  @doc "Batch query variant of `list/1`."
  @spec list_query(keyword()) :: Batch.Request.t()
  def list_query(opts \\ []), do: build_query("GET", "/groups", nil, opts)

  @doc """
  Gets a group by ID.
  """
  @spec get(String.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def get(group_id, opts \\ []), do: Resource.execute(get_query(group_id, opts), opts)

  @doc "Batch query variant of `get/2`."
  @spec get_query(String.t(), keyword()) :: Batch.Request.t()
  def get_query(group_id, opts \\ []), do: build_query("GET", "/groups/#{group_id}", nil, opts)

  @doc """
  Creates a new group.
  """
  @spec create(map(), keyword()) :: {:ok, map()} | {:error, term()}
  def create(attrs, opts \\ []), do: Resource.execute(create_query(attrs, opts), opts)

  @doc "Batch query variant of `create/2`."
  @spec create_query(map(), keyword()) :: Batch.Request.t()
  def create_query(attrs, opts \\ []), do: build_query("POST", "/groups", attrs, opts)

  @doc """
  Updates a group.
  """
  @spec update(String.t(), map(), keyword()) :: {:ok, map()} | :ok | {:error, term()}
  def update(group_id, attrs, opts \\ []), do: Resource.execute(update_query(group_id, attrs, opts), opts)

  @doc "Batch query variant of `update/3`."
  @spec update_query(String.t(), map(), keyword()) :: Batch.Request.t()
  def update_query(group_id, attrs, opts \\ []), do: build_query("PATCH", "/groups/#{group_id}", attrs, opts)

  @doc """
  Deletes a group.
  """
  @spec delete(String.t(), keyword()) :: :ok | {:error, term()}
  def delete(group_id, opts \\ []), do: Resource.execute(delete_query(group_id, opts), opts)

  @doc "Batch query variant of `delete/2`."
  @spec delete_query(String.t(), keyword()) :: Batch.Request.t()
  def delete_query(group_id, opts \\ []), do: build_query("DELETE", "/groups/#{group_id}", nil, opts)

  @doc """
  Lists members of a group.
  """
  @spec list_members(String.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def list_members(group_id, opts \\ []), do: Resource.execute(list_members_query(group_id, opts), opts)

  @doc "Batch query variant of `list_members/2`."
  @spec list_members_query(String.t(), keyword()) :: Batch.Request.t()
  def list_members_query(group_id, opts \\ []), do: build_query("GET", "/groups/#{group_id}/members", nil, opts)

  @doc """
  Adds a member to a group.

  The `member_id` should be the directory object ID of the user or service principal.
  """
  @spec add_member(String.t(), String.t(), keyword()) :: :ok | {:error, term()}
  def add_member(group_id, member_id, opts \\ []), do: Resource.execute(add_member_query(group_id, member_id, opts), opts)

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
  def remove_member(group_id, member_id, opts \\ []), do: Resource.execute(remove_member_query(group_id, member_id, opts), opts)

  @doc "Batch query variant of `remove_member/3`."
  @spec remove_member_query(String.t(), String.t(), keyword()) :: Batch.Request.t()
  def remove_member_query(group_id, member_id, opts \\ []) do
    build_query("DELETE", "/groups/#{group_id}/members/#{member_id}/$ref", nil, opts)
  end

  @doc """
  Lists owners of a group.
  """
  @spec list_owners(String.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def list_owners(group_id, opts \\ []), do: Resource.execute(list_owners_query(group_id, opts), opts)

  @doc "Batch query variant of `list_owners/2`."
  @spec list_owners_query(String.t(), keyword()) :: Batch.Request.t()
  def list_owners_query(group_id, opts \\ []), do: build_query("GET", "/groups/#{group_id}/owners", nil, opts)

  @doc """
  Adds an owner to a group.

  The `owner_id` should be the directory object ID of the user.
  """
  @spec add_owner(String.t(), String.t(), keyword()) :: :ok | {:error, term()}
  def add_owner(group_id, owner_id, opts \\ []), do: Resource.execute(add_owner_query(group_id, owner_id, opts), opts)

  @doc "Batch query variant of `add_owner/3`."
  @spec add_owner_query(String.t(), String.t(), keyword()) :: Batch.Request.t()
  def add_owner_query(group_id, owner_id, opts \\ []) do
    body = %{"@odata.id" => "https://graph.microsoft.com/v1.0/directoryObjects/#{owner_id}"}
    build_query("POST", "/groups/#{group_id}/owners/$ref", body, opts)
  end

  @doc """
  Removes an owner from a group.
  """
  @spec remove_owner(String.t(), String.t(), keyword()) :: :ok | {:error, term()}
  def remove_owner(group_id, owner_id, opts \\ []), do: Resource.execute(remove_owner_query(group_id, owner_id, opts), opts)

  @doc "Batch query variant of `remove_owner/3`."
  @spec remove_owner_query(String.t(), String.t(), keyword()) :: Batch.Request.t()
  def remove_owner_query(group_id, owner_id, opts \\ []) do
    build_query("DELETE", "/groups/#{group_id}/owners/#{owner_id}/$ref", nil, opts)
  end

  @doc """
  Lists transitive members of a group.
  """
  @spec list_transitive_members(String.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def list_transitive_members(group_id, opts \\ []), do: Resource.execute(list_transitive_members_query(group_id, opts), opts)

  @doc "Batch query variant of `list_transitive_members/2`."
  @spec list_transitive_members_query(String.t(), keyword()) :: Batch.Request.t()
  def list_transitive_members_query(group_id, opts \\ []), do: build_query("GET", "/groups/#{group_id}/transitiveMembers", nil, opts)

  @doc """
  Lists groups and directory roles the group is a member of.
  """
  @spec list_member_of(String.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def list_member_of(group_id, opts \\ []), do: Resource.execute(list_member_of_query(group_id, opts), opts)

  @doc "Batch query variant of `list_member_of/2`."
  @spec list_member_of_query(String.t(), keyword()) :: Batch.Request.t()
  def list_member_of_query(group_id, opts \\ []), do: build_query("GET", "/groups/#{group_id}/memberOf", nil, opts)

  @doc """
  Assigns licenses to a group.
  """
  @spec assign_license(String.t(), map(), keyword()) :: {:ok, map()} | {:error, term()}
  def assign_license(group_id, attrs, opts \\ []), do: Resource.execute(assign_license_query(group_id, attrs, opts), opts)

  @doc "Batch query variant of `assign_license/3`."
  @spec assign_license_query(String.t(), map(), keyword()) :: Batch.Request.t()
  def assign_license_query(group_id, attrs, opts \\ []), do: build_query("POST", "/groups/#{group_id}/assignLicense", attrs, opts)

  @doc """
  Renews a group's expiration.
  """
  @spec renew(String.t(), keyword()) :: :ok | {:error, term()}
  def renew(group_id, opts \\ []), do: Resource.execute(renew_query(group_id, opts), opts)

  @doc "Batch query variant of `renew/2`."
  @spec renew_query(String.t(), keyword()) :: Batch.Request.t()
  def renew_query(group_id, opts \\ []), do: build_query("POST", "/groups/#{group_id}/renew", nil, opts)

  # ---------------------------------------------------------------------------
  # Membership introspection
  # ---------------------------------------------------------------------------

  @doc """
  Lists groups and directory roles the group is a transitive member of.
  """
  @spec list_transitive_member_of(String.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def list_transitive_member_of(group_id, opts \\ []), do: Resource.execute(list_transitive_member_of_query(group_id, opts), opts)

  @doc "Batch query variant of `list_transitive_member_of/2`."
  @spec list_transitive_member_of_query(String.t(), keyword()) :: Batch.Request.t()
  def list_transitive_member_of_query(group_id, opts \\ []), do: build_query("GET", "/groups/#{group_id}/transitiveMemberOf", nil, opts)

  @doc """
  Returns all group and directory role IDs the group is a member of (transitive).
  """
  @spec get_member_objects(String.t(), map(), keyword()) :: {:ok, map()} | {:error, term()}
  def get_member_objects(group_id, attrs, opts \\ []), do: Resource.execute(get_member_objects_query(group_id, attrs, opts), opts)

  @doc "Batch query variant of `get_member_objects/3`."
  @spec get_member_objects_query(String.t(), map(), keyword()) :: Batch.Request.t()
  def get_member_objects_query(group_id, attrs, opts \\ []), do: build_query("POST", "/groups/#{group_id}/getMemberObjects", attrs, opts)

  @doc """
  Returns all group IDs the group is a member of (transitive).
  """
  @spec get_member_groups(String.t(), map(), keyword()) :: {:ok, map()} | {:error, term()}
  def get_member_groups(group_id, attrs, opts \\ []), do: Resource.execute(get_member_groups_query(group_id, attrs, opts), opts)

  @doc "Batch query variant of `get_member_groups/3`."
  @spec get_member_groups_query(String.t(), map(), keyword()) :: Batch.Request.t()
  def get_member_groups_query(group_id, attrs, opts \\ []), do: build_query("POST", "/groups/#{group_id}/getMemberGroups", attrs, opts)

  @doc """
  Checks whether the group is a member of the specified objects.
  """
  @spec check_member_objects(String.t(), map(), keyword()) :: {:ok, map()} | {:error, term()}
  def check_member_objects(group_id, attrs, opts \\ []), do: Resource.execute(check_member_objects_query(group_id, attrs, opts), opts)

  @doc "Batch query variant of `check_member_objects/3`."
  @spec check_member_objects_query(String.t(), map(), keyword()) :: Batch.Request.t()
  def check_member_objects_query(group_id, attrs, opts \\ []), do: build_query("POST", "/groups/#{group_id}/checkMemberObjects", attrs, opts)

  @doc """
  Checks whether the group is a member of the specified groups.
  """
  @spec check_member_groups(String.t(), map(), keyword()) :: {:ok, map()} | {:error, term()}
  def check_member_groups(group_id, attrs, opts \\ []), do: Resource.execute(check_member_groups_query(group_id, attrs, opts), opts)

  @doc "Batch query variant of `check_member_groups/3`."
  @spec check_member_groups_query(String.t(), map(), keyword()) :: Batch.Request.t()
  def check_member_groups_query(group_id, attrs, opts \\ []), do: build_query("POST", "/groups/#{group_id}/checkMemberGroups", attrs, opts)

  # ---------------------------------------------------------------------------
  # App role assignments
  # ---------------------------------------------------------------------------

  @doc """
  Lists app role assignments for a group.
  """
  @spec list_app_role_assignments(String.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def list_app_role_assignments(group_id, opts \\ []), do: Resource.execute(list_app_role_assignments_query(group_id, opts), opts)

  @doc "Batch query variant of `list_app_role_assignments/2`."
  @spec list_app_role_assignments_query(String.t(), keyword()) :: Batch.Request.t()
  def list_app_role_assignments_query(group_id, opts \\ []), do: build_query("GET", "/groups/#{group_id}/appRoleAssignments", nil, opts)

  @doc """
  Adds an app role assignment to a group.
  """
  @spec add_app_role_assignment(String.t(), map(), keyword()) :: {:ok, map()} | {:error, term()}
  def add_app_role_assignment(group_id, attrs, opts \\ []), do: Resource.execute(add_app_role_assignment_query(group_id, attrs, opts), opts)

  @doc "Batch query variant of `add_app_role_assignment/3`."
  @spec add_app_role_assignment_query(String.t(), map(), keyword()) :: Batch.Request.t()
  def add_app_role_assignment_query(group_id, attrs, opts \\ []), do: build_query("POST", "/groups/#{group_id}/appRoleAssignments", attrs, opts)

  @doc """
  Removes an app role assignment from a group.
  """
  @spec remove_app_role_assignment(String.t(), String.t(), keyword()) :: :ok | {:error, term()}
  def remove_app_role_assignment(group_id, assignment_id, opts \\ []), do: Resource.execute(remove_app_role_assignment_query(group_id, assignment_id, opts), opts)

  @doc "Batch query variant of `remove_app_role_assignment/3`."
  @spec remove_app_role_assignment_query(String.t(), String.t(), keyword()) :: Batch.Request.t()
  def remove_app_role_assignment_query(group_id, assignment_id, opts \\ []), do: build_query("DELETE", "/groups/#{group_id}/appRoleAssignments/#{assignment_id}", nil, opts)

  # ---------------------------------------------------------------------------
  # Permission grants
  # ---------------------------------------------------------------------------

  @doc """
  Lists resource-specific permission grants on a group.
  """
  @spec list_permission_grants(String.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def list_permission_grants(group_id, opts \\ []), do: Resource.execute(list_permission_grants_query(group_id, opts), opts)

  @doc "Batch query variant of `list_permission_grants/2`."
  @spec list_permission_grants_query(String.t(), keyword()) :: Batch.Request.t()
  def list_permission_grants_query(group_id, opts \\ []), do: build_query("GET", "/groups/#{group_id}/permissionGrants", nil, opts)

  # ---------------------------------------------------------------------------
  # Delta
  # ---------------------------------------------------------------------------

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
