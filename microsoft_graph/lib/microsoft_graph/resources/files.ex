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
