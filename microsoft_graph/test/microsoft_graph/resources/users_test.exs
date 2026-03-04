defmodule MicrosoftGraph.UsersTest do
  use ExUnit.Case, async: true

  alias MicrosoftGraph.Test.Fixtures
  alias MicrosoftGraph.Users

  setup do
    stub_name = :"users_test_#{System.unique_integer([:positive])}"

    Req.Test.stub(stub_name, fn conn ->
      case {conn.method, conn.request_path} do
        {"GET", "/users"} ->
          Req.Test.json(conn, Fixtures.load("users/list.json"))

        {"GET", "/users/user-id-1"} ->
          Req.Test.json(conn, Fixtures.load("users/get.json"))

        {"POST", "/users"} ->
          conn
          |> Plug.Conn.put_status(201)
          |> Req.Test.json(%{"id" => "new-user-id", "displayName" => "New User"})

        {"PATCH", "/users/user-id-1"} ->
          Req.Test.json(conn, %{"id" => "user-id-1", "displayName" => "Updated"})

        {"DELETE", "/users/user-id-1"} ->
          Plug.Conn.send_resp(conn, 204, "")

        {"GET", "/users/user-id-1/directReports"} ->
          Req.Test.json(conn, %{"value" => [%{"id" => "report-1"}]})

        {"GET", "/users/user-id-1/memberOf"} ->
          Req.Test.json(conn, %{"value" => [%{"id" => "group-1"}]})

        _ ->
          Plug.Conn.send_resp(conn, 404, "")
      end
    end)

    client = Req.new(plug: {Req.Test, stub_name})
    %{client: client}
  end

  describe "list/1" do
    test "returns list of users", %{client: client} do
      assert {:ok, %{"value" => users}} = Users.list(client: client)
      assert length(users) == 2
      assert hd(users)["displayName"] == "Alice Smith"
    end
  end

  describe "get/2" do
    test "returns a single user", %{client: client} do
      assert {:ok, user} = Users.get("user-id-1", client: client)
      assert user["displayName"] == "Alice Smith"
      assert user["mail"] == "alice@contoso.com"
    end
  end

  describe "create/2" do
    test "creates a user", %{client: client} do
      attrs = %{"displayName" => "New User", "mailNickname" => "newuser"}
      assert {:ok, user} = Users.create(attrs, client: client)
      assert user["id"] == "new-user-id"
    end
  end

  describe "update/3" do
    test "updates a user", %{client: client} do
      assert {:ok, user} =
               Users.update("user-id-1", %{"displayName" => "Updated"}, client: client)

      assert user["displayName"] == "Updated"
    end
  end

  describe "delete/2" do
    test "deletes a user", %{client: client} do
      assert :ok = Users.delete("user-id-1", client: client)
    end
  end

  describe "list_direct_reports/2" do
    test "returns direct reports", %{client: client} do
      assert {:ok, %{"value" => reports}} = Users.list_direct_reports("user-id-1", client: client)
      assert length(reports) == 1
    end
  end

  describe "list_member_of/2" do
    test "returns memberships", %{client: client} do
      assert {:ok, %{"value" => groups}} = Users.list_member_of("user-id-1", client: client)
      assert length(groups) == 1
    end
  end
end
