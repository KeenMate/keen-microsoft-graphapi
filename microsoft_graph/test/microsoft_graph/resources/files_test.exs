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
end
