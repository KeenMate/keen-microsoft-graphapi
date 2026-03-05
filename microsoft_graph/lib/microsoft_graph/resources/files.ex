defmodule MicrosoftGraph.Files do
  @moduledoc """
  Operations on OneDrive/SharePoint files (`/drives`, `/drive/items`, etc.).

  ## Examples

      {:ok, drive} = MicrosoftGraph.Files.get_drive("user-id")
      {:ok, %{"value" => items}} = MicrosoftGraph.Files.list_root_children("drive-id")
      {:ok, content} = MicrosoftGraph.Files.download_content("drive-id", "item-id")
  """

  alias MicrosoftGraph.Batch
  alias MicrosoftGraph.Delta
  alias MicrosoftGraph.Resource
  alias MicrosoftGraph.Response

  @doc """
  Gets a user's default drive.
  """
  @spec get_drive(String.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def get_drive(user_id, opts \\ []), do: Resource.execute(get_drive_query(user_id, opts), opts)

  @doc "Batch query variant of `get_drive/2`."
  @spec get_drive_query(String.t(), keyword()) :: Batch.Request.t()
  def get_drive_query(user_id, opts \\ []), do: build_query("GET", "/users/#{user_id}/drive", nil, opts)

  @doc """
  Lists children of the root folder in a drive.
  """
  @spec list_root_children(String.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def list_root_children(drive_id, opts \\ []), do: Resource.execute(list_root_children_query(drive_id, opts), opts)

  @doc "Batch query variant of `list_root_children/2`."
  @spec list_root_children_query(String.t(), keyword()) :: Batch.Request.t()
  def list_root_children_query(drive_id, opts \\ []), do: build_query("GET", "/drives/#{drive_id}/root/children", nil, opts)

  @doc """
  Lists children of a specific item in a drive.
  """
  @spec list_children(String.t(), String.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def list_children(drive_id, item_id, opts \\ []), do: Resource.execute(list_children_query(drive_id, item_id, opts), opts)

  @doc "Batch query variant of `list_children/3`."
  @spec list_children_query(String.t(), String.t(), keyword()) :: Batch.Request.t()
  def list_children_query(drive_id, item_id, opts \\ []) do
    build_query("GET", "/drives/#{drive_id}/items/#{item_id}/children", nil, opts)
  end

  @doc """
  Gets a drive item by ID.
  """
  @spec get_item(String.t(), String.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def get_item(drive_id, item_id, opts \\ []), do: Resource.execute(get_item_query(drive_id, item_id, opts), opts)

  @doc "Batch query variant of `get_item/3`."
  @spec get_item_query(String.t(), String.t(), keyword()) :: Batch.Request.t()
  def get_item_query(drive_id, item_id, opts \\ []) do
    build_query("GET", "/drives/#{drive_id}/items/#{item_id}", nil, opts)
  end

  @doc """
  Gets a drive item by path.

  The path should be relative to the root (e.g., "Documents/report.docx").
  """
  @spec get_item_by_path(String.t(), String.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def get_item_by_path(drive_id, path, opts \\ []), do: Resource.execute(get_item_by_path_query(drive_id, path, opts), opts)

  @doc "Batch query variant of `get_item_by_path/3`."
  @spec get_item_by_path_query(String.t(), String.t(), keyword()) :: Batch.Request.t()
  def get_item_by_path_query(drive_id, path, opts \\ []) do
    encoded_path = URI.encode(path)
    build_query("GET", "/drives/#{drive_id}/root:/#{encoded_path}:", nil, opts)
  end

  @doc """
  Downloads the content of a drive item.

  Returns `{:ok, binary}` with the raw file content.
  """
  @spec download_content(String.t(), String.t(), keyword()) ::
          {:ok, binary()} | {:error, term()}
  def download_content(drive_id, item_id, opts \\ []) do
    client = Resource.resolve_client(opts)

    req_opts = [url: "/drives/#{drive_id}/items/#{item_id}/content"]
    req_opts = maybe_put_token(req_opts, opts)

    client
    |> Req.get(req_opts)
    |> Response.normalize()
  end

  @doc "Batch query variant of `download_content/3`."
  @spec download_content_query(String.t(), String.t(), keyword()) :: Batch.Request.t()
  def download_content_query(drive_id, item_id, opts \\ []) do
    build_query("GET", "/drives/#{drive_id}/items/#{item_id}/content", nil, opts)
  end

  @doc """
  Uploads a small file (up to 4 MB) to a drive.

  For larger files, use `create_upload_session/4`.
  """
  @spec upload_small(String.t(), String.t(), binary(), keyword()) ::
          {:ok, map()} | {:error, term()}
  def upload_small(drive_id, path, content, opts \\ []) do
    client = Resource.resolve_client(opts)
    encoded_path = URI.encode(path)

    req_opts = [
      url: "/drives/#{drive_id}/root:/#{encoded_path}:/content",
      body: content,
      headers: [{"content-type", "application/octet-stream"}]
    ]

    req_opts = maybe_put_token(req_opts, opts)

    client
    |> Req.put(req_opts)
    |> Response.normalize()
  end

  @doc "Batch query variant of `upload_small/4`."
  @spec upload_small_query(String.t(), String.t(), binary(), keyword()) :: Batch.Request.t()
  def upload_small_query(drive_id, path, content, opts \\ []) do
    encoded_path = URI.encode(path)
    {as, opts} = Keyword.pop(opts, :as)
    {query, _opts} = Keyword.pop(opts, :query)

    %Batch.Request{
      method: "PUT",
      url: "/drives/#{drive_id}/root:/#{encoded_path}:/content",
      body: content,
      headers: %{"Content-Type" => "application/octet-stream"},
      query: query,
      as: as
    }
  end

  @doc """
  Creates an upload session for large file uploads (> 4 MB).

  Returns the upload URL to use for uploading file chunks.
  """
  @spec create_upload_session(String.t(), String.t(), map(), keyword()) ::
          {:ok, map()} | {:error, term()}
  def create_upload_session(drive_id, path, attrs \\ %{}, opts \\ []) do
    Resource.execute(create_upload_session_query(drive_id, path, attrs, opts), opts)
  end

  @doc "Batch query variant of `create_upload_session/4`."
  @spec create_upload_session_query(String.t(), String.t(), map(), keyword()) :: Batch.Request.t()
  def create_upload_session_query(drive_id, path, attrs \\ %{}, opts \\ []) do
    encoded_path = URI.encode(path)
    body = %{"item" => attrs}
    build_query("POST", "/drives/#{drive_id}/root:/#{encoded_path}:/createUploadSession", body, opts)
  end

  # ---------------------------------------------------------------------------
  # Drive-level
  # ---------------------------------------------------------------------------

  @doc """
  Lists all drives available to a user.
  """
  @spec list_drives(String.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def list_drives(user_id, opts \\ []), do: Resource.execute(list_drives_query(user_id, opts), opts)

  @doc "Batch query variant of `list_drives/2`."
  @spec list_drives_query(String.t(), keyword()) :: Batch.Request.t()
  def list_drives_query(user_id, opts \\ []), do: build_query("GET", "/users/#{user_id}/drives", nil, opts)

  @doc """
  Gets a special folder (e.g., "documents", "photos", "approot") in a drive.
  """
  @spec get_special_folder(String.t(), String.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def get_special_folder(drive_id, name, opts \\ []), do: Resource.execute(get_special_folder_query(drive_id, name, opts), opts)

  @doc "Batch query variant of `get_special_folder/3`."
  @spec get_special_folder_query(String.t(), String.t(), keyword()) :: Batch.Request.t()
  def get_special_folder_query(drive_id, name, opts \\ []) do
    build_query("GET", "/drives/#{drive_id}/special/#{name}", nil, opts)
  end

  @doc """
  Searches for items in a drive matching the given query string.
  """
  @spec search(String.t(), String.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def search(drive_id, query, opts \\ []), do: Resource.execute(search_query(drive_id, query, opts), opts)

  @doc "Batch query variant of `search/3`."
  @spec search_query(String.t(), String.t(), keyword()) :: Batch.Request.t()
  def search_query(drive_id, query, opts \\ []) do
    encoded_query = URI.encode(query)
    build_query("GET", "/drives/#{drive_id}/root/search(q='#{encoded_query}')", nil, opts)
  end

  # ---------------------------------------------------------------------------
  # Item CRUD
  # ---------------------------------------------------------------------------

  @doc """
  Creates a new folder under the given parent item.
  """
  @spec create_folder(String.t(), String.t(), map(), keyword()) :: {:ok, map()} | {:error, term()}
  def create_folder(drive_id, parent_item_id, attrs, opts \\ []) do
    Resource.execute(create_folder_query(drive_id, parent_item_id, attrs, opts), opts)
  end

  @doc "Batch query variant of `create_folder/4`."
  @spec create_folder_query(String.t(), String.t(), map(), keyword()) :: Batch.Request.t()
  def create_folder_query(drive_id, parent_item_id, attrs, opts \\ []) do
    body = Map.merge(%{"folder" => %{}, "@microsoft.graph.conflictBehavior" => "rename"}, attrs)
    build_query("POST", "/drives/#{drive_id}/items/#{parent_item_id}/children", body, opts)
  end

  @doc """
  Updates a drive item's metadata (name, description, etc.).
  """
  @spec update_item(String.t(), String.t(), map(), keyword()) :: {:ok, map()} | {:error, term()}
  def update_item(drive_id, item_id, attrs, opts \\ []) do
    Resource.execute(update_item_query(drive_id, item_id, attrs, opts), opts)
  end

  @doc "Batch query variant of `update_item/4`."
  @spec update_item_query(String.t(), String.t(), map(), keyword()) :: Batch.Request.t()
  def update_item_query(drive_id, item_id, attrs, opts \\ []) do
    build_query("PATCH", "/drives/#{drive_id}/items/#{item_id}", attrs, opts)
  end

  @doc """
  Deletes a drive item.
  """
  @spec delete_item(String.t(), String.t(), keyword()) :: :ok | {:error, term()}
  def delete_item(drive_id, item_id, opts \\ []) do
    Resource.execute(delete_item_query(drive_id, item_id, opts), opts)
  end

  @doc "Batch query variant of `delete_item/3`."
  @spec delete_item_query(String.t(), String.t(), keyword()) :: Batch.Request.t()
  def delete_item_query(drive_id, item_id, opts \\ []) do
    build_query("DELETE", "/drives/#{drive_id}/items/#{item_id}", nil, opts)
  end

  @doc """
  Copies a drive item to a new location. Returns 202 Accepted with an async monitor URL.
  """
  @spec copy_item(String.t(), String.t(), map(), keyword()) :: {:ok, map()} | {:error, term()}
  def copy_item(drive_id, item_id, attrs, opts \\ []) do
    Resource.execute(copy_item_query(drive_id, item_id, attrs, opts), opts)
  end

  @doc "Batch query variant of `copy_item/4`."
  @spec copy_item_query(String.t(), String.t(), map(), keyword()) :: Batch.Request.t()
  def copy_item_query(drive_id, item_id, attrs, opts \\ []) do
    build_query("POST", "/drives/#{drive_id}/items/#{item_id}/copy", attrs, opts)
  end

  # ---------------------------------------------------------------------------
  # Permissions
  # ---------------------------------------------------------------------------

  @doc """
  Lists permissions on a drive item.
  """
  @spec list_permissions(String.t(), String.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def list_permissions(drive_id, item_id, opts \\ []) do
    Resource.execute(list_permissions_query(drive_id, item_id, opts), opts)
  end

  @doc "Batch query variant of `list_permissions/3`."
  @spec list_permissions_query(String.t(), String.t(), keyword()) :: Batch.Request.t()
  def list_permissions_query(drive_id, item_id, opts \\ []) do
    build_query("GET", "/drives/#{drive_id}/items/#{item_id}/permissions", nil, opts)
  end

  @doc """
  Creates a sharing link for a drive item.
  """
  @spec create_sharing_link(String.t(), String.t(), map(), keyword()) :: {:ok, map()} | {:error, term()}
  def create_sharing_link(drive_id, item_id, attrs, opts \\ []) do
    Resource.execute(create_sharing_link_query(drive_id, item_id, attrs, opts), opts)
  end

  @doc "Batch query variant of `create_sharing_link/4`."
  @spec create_sharing_link_query(String.t(), String.t(), map(), keyword()) :: Batch.Request.t()
  def create_sharing_link_query(drive_id, item_id, attrs, opts \\ []) do
    build_query("POST", "/drives/#{drive_id}/items/#{item_id}/createLink", attrs, opts)
  end

  @doc """
  Invites recipients and adds permissions to a drive item.
  """
  @spec add_permission(String.t(), String.t(), map(), keyword()) :: {:ok, map()} | {:error, term()}
  def add_permission(drive_id, item_id, attrs, opts \\ []) do
    Resource.execute(add_permission_query(drive_id, item_id, attrs, opts), opts)
  end

  @doc "Batch query variant of `add_permission/4`."
  @spec add_permission_query(String.t(), String.t(), map(), keyword()) :: Batch.Request.t()
  def add_permission_query(drive_id, item_id, attrs, opts \\ []) do
    build_query("POST", "/drives/#{drive_id}/items/#{item_id}/invite", attrs, opts)
  end

  @doc """
  Deletes a permission from a drive item.
  """
  @spec delete_permission(String.t(), String.t(), String.t(), keyword()) :: :ok | {:error, term()}
  def delete_permission(drive_id, item_id, perm_id, opts \\ []) do
    Resource.execute(delete_permission_query(drive_id, item_id, perm_id, opts), opts)
  end

  @doc "Batch query variant of `delete_permission/4`."
  @spec delete_permission_query(String.t(), String.t(), String.t(), keyword()) :: Batch.Request.t()
  def delete_permission_query(drive_id, item_id, perm_id, opts \\ []) do
    build_query("DELETE", "/drives/#{drive_id}/items/#{item_id}/permissions/#{perm_id}", nil, opts)
  end

  # ---------------------------------------------------------------------------
  # Versions & Thumbnails
  # ---------------------------------------------------------------------------

  @doc """
  Lists versions of a drive item.
  """
  @spec list_versions(String.t(), String.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def list_versions(drive_id, item_id, opts \\ []) do
    Resource.execute(list_versions_query(drive_id, item_id, opts), opts)
  end

  @doc "Batch query variant of `list_versions/3`."
  @spec list_versions_query(String.t(), String.t(), keyword()) :: Batch.Request.t()
  def list_versions_query(drive_id, item_id, opts \\ []) do
    build_query("GET", "/drives/#{drive_id}/items/#{item_id}/versions", nil, opts)
  end

  @doc """
  Lists thumbnails for a drive item.
  """
  @spec list_thumbnails(String.t(), String.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def list_thumbnails(drive_id, item_id, opts \\ []) do
    Resource.execute(list_thumbnails_query(drive_id, item_id, opts), opts)
  end

  @doc "Batch query variant of `list_thumbnails/3`."
  @spec list_thumbnails_query(String.t(), String.t(), keyword()) :: Batch.Request.t()
  def list_thumbnails_query(drive_id, item_id, opts \\ []) do
    build_query("GET", "/drives/#{drive_id}/items/#{item_id}/thumbnails", nil, opts)
  end

  # ---------------------------------------------------------------------------
  # Shared Items
  # ---------------------------------------------------------------------------

  @doc """
  Gets a shared drive item by its sharing token or encoded sharing URL.
  """
  @spec get_shared_item(String.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def get_shared_item(share_id, opts \\ []), do: Resource.execute(get_shared_item_query(share_id, opts), opts)

  @doc "Batch query variant of `get_shared_item/2`."
  @spec get_shared_item_query(String.t(), keyword()) :: Batch.Request.t()
  def get_shared_item_query(share_id, opts \\ []), do: build_query("GET", "/shares/#{share_id}/driveItem", nil, opts)

  # ---------------------------------------------------------------------------
  # Delta
  # ---------------------------------------------------------------------------

  @doc """
  Delta query for a drive's root folder. Returns file/folder changes since the last sync.
  """
  @spec drive_delta(String.t(), keyword()) :: {:ok, Delta.delta_page()} | {:error, term()}
  def drive_delta(drive_id, opts \\ []), do: Delta.query("/drives/#{drive_id}/root/delta", opts)

  @doc "Batch query variant of `drive_delta/2`."
  @spec drive_delta_query(String.t(), keyword()) :: Batch.Request.t()
  def drive_delta_query(drive_id, opts \\ []), do: build_query("GET", "/drives/#{drive_id}/root/delta", nil, opts)

  defp maybe_put_token(req_opts, opts) do
    case Keyword.get(opts, :access_token) do
      nil -> req_opts
      token -> Keyword.put(req_opts, :access_token, token)
    end
  end

  defp build_query(method, url, body, opts) do
    {as, opts} = Keyword.pop(opts, :as)
    {query, _opts} = Keyword.pop(opts, :query)
    %Batch.Request{method: method, url: url, body: body, query: query, as: as}
  end
end
