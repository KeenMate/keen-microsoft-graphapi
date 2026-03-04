defmodule MicrosoftGraph.Files do
  @moduledoc """
  Operations on OneDrive/SharePoint files (`/drives`, `/drive/items`, etc.).

  ## Examples

      {:ok, drive} = MicrosoftGraph.Files.get_drive("user-id")
      {:ok, %{"value" => items}} = MicrosoftGraph.Files.list_root_children("drive-id")
      {:ok, content} = MicrosoftGraph.Files.download_content("drive-id", "item-id")
  """

  alias MicrosoftGraph.Resource
  alias MicrosoftGraph.Response

  @doc """
  Gets a user's default drive.
  """
  @spec get_drive(String.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def get_drive(user_id, opts \\ []) do
    Resource.get("/users/#{user_id}/drive", opts)
  end

  @doc """
  Lists children of the root folder in a drive.
  """
  @spec list_root_children(String.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def list_root_children(drive_id, opts \\ []) do
    Resource.get("/drives/#{drive_id}/root/children", opts)
  end

  @doc """
  Lists children of a specific item in a drive.
  """
  @spec list_children(String.t(), String.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def list_children(drive_id, item_id, opts \\ []) do
    Resource.get("/drives/#{drive_id}/items/#{item_id}/children", opts)
  end

  @doc """
  Gets a drive item by ID.
  """
  @spec get_item(String.t(), String.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def get_item(drive_id, item_id, opts \\ []) do
    Resource.get("/drives/#{drive_id}/items/#{item_id}", opts)
  end

  @doc """
  Gets a drive item by path.

  The path should be relative to the root (e.g., "Documents/report.docx").
  """
  @spec get_item_by_path(String.t(), String.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def get_item_by_path(drive_id, path, opts \\ []) do
    encoded_path = URI.encode(path)
    Resource.get("/drives/#{drive_id}/root:/#{encoded_path}:", opts)
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

  @doc """
  Creates an upload session for large file uploads (> 4 MB).

  Returns the upload URL to use for uploading file chunks.
  """
  @spec create_upload_session(String.t(), String.t(), map(), keyword()) ::
          {:ok, map()} | {:error, term()}
  def create_upload_session(drive_id, path, attrs \\ %{}, opts \\ []) do
    encoded_path = URI.encode(path)
    body = %{"item" => attrs}
    Resource.post("/drives/#{drive_id}/root:/#{encoded_path}:/createUploadSession", body, opts)
  end

  defp maybe_put_token(req_opts, opts) do
    case Keyword.get(opts, :access_token) do
      nil -> req_opts
      token -> Keyword.put(req_opts, :access_token, token)
    end
  end
end
