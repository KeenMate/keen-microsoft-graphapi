defmodule MicrosoftGraph.FilesTest do
  use ExUnit.Case, async: true

  alias MicrosoftGraph.Files
  alias MicrosoftGraph.Test.Fixtures

  setup do
    stub_name = :"files_test_#{System.unique_integer([:positive])}"

    Req.Test.stub(stub_name, fn conn ->
      case {conn.method, conn.request_path} do
        {"GET", "/users/user-1/drive"} ->
          Req.Test.json(conn, Fixtures.load("files/drive.json"))

        {"GET", "/users/user-1/drives"} ->
          Req.Test.json(conn, %{
            "value" => [
              %{"id" => "drive-1", "driveType" => "personal"},
              %{"id" => "drive-2", "driveType" => "business"}
            ]
          })

        {"GET", "/drives/drive-1/special/documents"} ->
          Req.Test.json(conn, %{"id" => "special-docs", "name" => "Documents"})

        {"GET", "/drives/drive-1/root/search(q='quarterly')"} ->
          Req.Test.json(conn, %{
            "value" => [%{"id" => "item-1", "name" => "quarterly-report.docx"}]
          })

        {"GET", "/drives/drive-1/root/children"} ->
          Req.Test.json(conn, Fixtures.load("files/children.json"))

        {"GET", "/drives/drive-1/items/item-1/children"} ->
          Req.Test.json(conn, Fixtures.load("files/children.json"))

        {"GET", "/drives/drive-1/items/item-1"} ->
          Req.Test.json(conn, %{
            "id" => "item-1",
            "name" => "report.docx",
            "size" => 102_400
          })

        {"GET", "/drives/drive-1/root:/Documents/report.docx:"} ->
          Req.Test.json(conn, %{
            "id" => "item-1",
            "name" => "report.docx"
          })

        {"GET", "/drives/drive-1/items/item-1/content"} ->
          Plug.Conn.send_resp(conn, 200, "file content bytes")

        {"PUT", "/drives/drive-1/root:/Documents/new.txt:/content"} ->
          conn
          |> Plug.Conn.put_status(201)
          |> Req.Test.json(%{"id" => "new-item-id", "name" => "new.txt"})

        {"POST", "/drives/drive-1/root:/bigfile.zip:/createUploadSession"} ->
          Req.Test.json(conn, %{
            "uploadUrl" => "https://upload.example.com/session123",
            "expirationDateTime" => "2024-01-16T10:30:00Z"
          })

        # Item CRUD
        {"POST", "/drives/drive-1/items/parent-1/children"} ->
          conn
          |> Plug.Conn.put_status(201)
          |> Req.Test.json(%{"id" => "new-folder-id", "name" => "New Folder", "folder" => %{"childCount" => 0}})

        {"PATCH", "/drives/drive-1/items/item-1"} ->
          Req.Test.json(conn, %{"id" => "item-1", "name" => "renamed.docx"})

        {"DELETE", "/drives/drive-1/items/item-1"} ->
          Plug.Conn.send_resp(conn, 204, "")

        {"POST", "/drives/drive-1/items/item-1/copy"} ->
          Plug.Conn.send_resp(conn, 202, "")

        # Permissions
        {"GET", "/drives/drive-1/items/item-1/permissions"} ->
          Req.Test.json(conn, %{
            "value" => [%{"id" => "perm-1", "roles" => ["read"]}]
          })

        {"POST", "/drives/drive-1/items/item-1/createLink"} ->
          conn
          |> Plug.Conn.put_status(201)
          |> Req.Test.json(%{
            "id" => "link-1",
            "link" => %{"type" => "view", "webUrl" => "https://example.com/share/link-1"}
          })

        {"POST", "/drives/drive-1/items/item-1/invite"} ->
          Req.Test.json(conn, %{
            "value" => [%{"id" => "perm-2", "roles" => ["write"]}]
          })

        {"DELETE", "/drives/drive-1/items/item-1/permissions/perm-1"} ->
          Plug.Conn.send_resp(conn, 204, "")

        # Versions & Thumbnails
        {"GET", "/drives/drive-1/items/item-1/versions"} ->
          Req.Test.json(conn, %{
            "value" => [%{"id" => "1.0"}, %{"id" => "2.0"}]
          })

        {"GET", "/drives/drive-1/items/item-1/thumbnails"} ->
          Req.Test.json(conn, %{
            "value" => [%{"id" => "0", "small" => %{"url" => "https://example.com/thumb/small"}}]
          })

        # Shared Items
        {"GET", "/shares/share-token-1/driveItem"} ->
          Req.Test.json(conn, %{"id" => "shared-item-1", "name" => "shared.docx"})

        _ ->
          Plug.Conn.send_resp(conn, 404, "")
      end
    end)

    client = Req.new(plug: {Req.Test, stub_name})
    %{client: client}
  end

  describe "get_drive/2" do
    test "returns a user's drive", %{client: client} do
      assert {:ok, drive} = Files.get_drive("user-1", client: client)
      assert drive["id"] == "drive-id-1"
      assert drive["driveType"] == "personal"
    end
  end

  describe "list_root_children/2" do
    test "returns root folder children", %{client: client} do
      assert {:ok, %{"value" => items}} = Files.list_root_children("drive-1", client: client)
      assert length(items) == 2
    end
  end

  describe "list_children/3" do
    test "returns item children", %{client: client} do
      assert {:ok, %{"value" => items}} = Files.list_children("drive-1", "item-1", client: client)
      assert length(items) == 2
    end
  end

  describe "get_item/3" do
    test "returns a drive item", %{client: client} do
      assert {:ok, item} = Files.get_item("drive-1", "item-1", client: client)
      assert item["name"] == "report.docx"
    end
  end

  describe "get_item_by_path/3" do
    test "returns item by path", %{client: client} do
      assert {:ok, item} =
               Files.get_item_by_path("drive-1", "Documents/report.docx", client: client)

      assert item["name"] == "report.docx"
    end
  end

  describe "download_content/3" do
    test "downloads file content", %{client: client} do
      assert {:ok, content} = Files.download_content("drive-1", "item-1", client: client)
      assert content == "file content bytes"
    end
  end

  describe "upload_small/4" do
    test "uploads a small file", %{client: client} do
      assert {:ok, item} =
               Files.upload_small("drive-1", "Documents/new.txt", "hello world", client: client)

      assert item["id"] == "new-item-id"
    end
  end

  describe "create_upload_session/4" do
    test "creates an upload session", %{client: client} do
      assert {:ok, session} =
               Files.create_upload_session("drive-1", "bigfile.zip", %{}, client: client)

      assert session["uploadUrl"] =~ "upload.example.com"
    end
  end

  # ---------------------------------------------------------------------------
  # Drive-level
  # ---------------------------------------------------------------------------

  describe "list_drives/2" do
    test "returns all drives for a user", %{client: client} do
      assert {:ok, %{"value" => drives}} = Files.list_drives("user-1", client: client)
      assert length(drives) == 2
      assert hd(drives)["id"] == "drive-1"
    end
  end

  describe "get_special_folder/3" do
    test "returns a special folder", %{client: client} do
      assert {:ok, folder} = Files.get_special_folder("drive-1", "documents", client: client)
      assert folder["id"] == "special-docs"
      assert folder["name"] == "Documents"
    end
  end

  describe "search/3" do
    test "searches for items", %{client: client} do
      assert {:ok, %{"value" => results}} = Files.search("drive-1", "quarterly", client: client)
      assert length(results) == 1
      assert hd(results)["name"] == "quarterly-report.docx"
    end
  end

  # ---------------------------------------------------------------------------
  # Item CRUD
  # ---------------------------------------------------------------------------

  describe "create_folder/4" do
    test "creates a folder", %{client: client} do
      attrs = %{"name" => "New Folder"}

      assert {:ok, folder} =
               Files.create_folder("drive-1", "parent-1", attrs, client: client)

      assert folder["id"] == "new-folder-id"
      assert folder["folder"]["childCount"] == 0
    end
  end

  describe "update_item/4" do
    test "updates an item", %{client: client} do
      assert {:ok, item} =
               Files.update_item("drive-1", "item-1", %{"name" => "renamed.docx"}, client: client)

      assert item["name"] == "renamed.docx"
    end
  end

  describe "delete_item/3" do
    test "deletes an item", %{client: client} do
      assert :ok = Files.delete_item("drive-1", "item-1", client: client)
    end
  end

  describe "copy_item/4" do
    test "copies an item", %{client: client} do
      attrs = %{"parentReference" => %{"driveId" => "drive-1", "id" => "parent-1"}, "name" => "copy.docx"}
      assert :ok = Files.copy_item("drive-1", "item-1", attrs, client: client)
    end
  end

  # ---------------------------------------------------------------------------
  # Permissions
  # ---------------------------------------------------------------------------

  describe "list_permissions/3" do
    test "lists permissions", %{client: client} do
      assert {:ok, %{"value" => perms}} =
               Files.list_permissions("drive-1", "item-1", client: client)

      assert length(perms) == 1
      assert hd(perms)["id"] == "perm-1"
    end
  end

  describe "create_sharing_link/4" do
    test "creates a sharing link", %{client: client} do
      attrs = %{"type" => "view", "scope" => "anonymous"}

      assert {:ok, link} =
               Files.create_sharing_link("drive-1", "item-1", attrs, client: client)

      assert link["link"]["type"] == "view"
    end
  end

  describe "add_permission/4" do
    test "invites and adds permissions", %{client: client} do
      attrs = %{
        "recipients" => [%{"email" => "user@example.com"}],
        "roles" => ["write"],
        "message" => "Please collaborate"
      }

      assert {:ok, %{"value" => perms}} =
               Files.add_permission("drive-1", "item-1", attrs, client: client)

      assert hd(perms)["roles"] == ["write"]
    end
  end

  describe "delete_permission/4" do
    test "deletes a permission", %{client: client} do
      assert :ok = Files.delete_permission("drive-1", "item-1", "perm-1", client: client)
    end
  end

  # ---------------------------------------------------------------------------
  # Versions & Thumbnails
  # ---------------------------------------------------------------------------

  describe "list_versions/3" do
    test "lists item versions", %{client: client} do
      assert {:ok, %{"value" => versions}} =
               Files.list_versions("drive-1", "item-1", client: client)

      assert length(versions) == 2
    end
  end

  describe "list_thumbnails/3" do
    test "lists item thumbnails", %{client: client} do
      assert {:ok, %{"value" => thumbnails}} =
               Files.list_thumbnails("drive-1", "item-1", client: client)

      assert length(thumbnails) == 1
    end
  end

  # ---------------------------------------------------------------------------
  # Shared Items
  # ---------------------------------------------------------------------------

  describe "get_shared_item/2" do
    test "gets a shared item by share token", %{client: client} do
      assert {:ok, item} = Files.get_shared_item("share-token-1", client: client)
      assert item["id"] == "shared-item-1"
      assert item["name"] == "shared.docx"
    end
  end
end
