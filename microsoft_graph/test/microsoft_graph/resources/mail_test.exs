defmodule MicrosoftGraph.MailTest do
  use ExUnit.Case, async: true

  alias MicrosoftGraph.Mail
  alias MicrosoftGraph.Test.Fixtures

  setup do
    stub_name = :"mail_test_#{System.unique_integer([:positive])}"

    Req.Test.stub(stub_name, fn conn ->
      case {conn.method, conn.request_path} do
        {"GET", "/users/user-1/messages"} ->
          Req.Test.json(conn, Fixtures.load("mail/list_messages.json"))

        {"GET", "/users/user-1/messages/msg-1"} ->
          Req.Test.json(conn, %{
            "id" => "msg-1",
            "subject" => "Hello",
            "bodyPreview" => "Hi there"
          })

        {"POST", "/users/user-1/sendMail"} ->
          Plug.Conn.send_resp(conn, 202, "")

        {"POST", "/users/user-1/messages"} ->
          conn
          |> Plug.Conn.put_status(201)
          |> Req.Test.json(%{"id" => "draft-1", "subject" => "Draft"})

        {"DELETE", "/users/user-1/messages/msg-1"} ->
          Plug.Conn.send_resp(conn, 204, "")

        {"GET", "/users/user-1/mailFolders"} ->
          Req.Test.json(conn, Fixtures.load("mail/mail_folders.json"))

        {"GET", "/users/user-1/mailFolders/folder-1/messages"} ->
          Req.Test.json(conn, Fixtures.load("mail/list_messages.json"))

        _ ->
          Plug.Conn.send_resp(conn, 404, "")
      end
    end)

    client = Req.new(plug: {Req.Test, stub_name})
    %{client: client}
  end

  describe "list_messages/2" do
    test "returns messages", %{client: client} do
      assert {:ok, %{"value" => messages}} = Mail.list_messages("user-1", client: client)
      assert length(messages) == 1
      assert hd(messages)["subject"] == "Hello World"
    end
  end

  describe "get_message/3" do
    test "returns a message", %{client: client} do
      assert {:ok, msg} = Mail.get_message("user-1", "msg-1", client: client)
      assert msg["subject"] == "Hello"
    end
  end

  describe "send_mail/3" do
    test "sends mail", %{client: client} do
      message = %{
        subject: "Hello",
        body: %{contentType: "Text", content: "Hi"},
        toRecipients: [%{emailAddress: %{address: "bob@contoso.com"}}]
      }

      assert :ok = Mail.send_mail("user-1", message, client: client)
    end
  end

  describe "create_draft/3" do
    test "creates a draft message", %{client: client} do
      assert {:ok, draft} = Mail.create_draft("user-1", %{subject: "Draft"}, client: client)
      assert draft["id"] == "draft-1"
    end
  end

  describe "delete_message/3" do
    test "deletes a message", %{client: client} do
      assert :ok = Mail.delete_message("user-1", "msg-1", client: client)
    end
  end

  describe "list_mail_folders/2" do
    test "returns mail folders", %{client: client} do
      assert {:ok, %{"value" => folders}} = Mail.list_mail_folders("user-1", client: client)
      assert length(folders) == 2
      assert hd(folders)["displayName"] == "Inbox"
    end
  end

  describe "list_folder_messages/3" do
    test "returns messages in a folder", %{client: client} do
      assert {:ok, %{"value" => messages}} =
               Mail.list_folder_messages("user-1", "folder-1", client: client)

      assert length(messages) == 1
    end
  end
end
