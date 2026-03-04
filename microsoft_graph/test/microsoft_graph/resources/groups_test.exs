defmodule MicrosoftGraph.GroupsTest do
  use ExUnit.Case, async: true

  alias MicrosoftGraph.Groups
  alias MicrosoftGraph.Test.Fixtures

  setup do
    stub_name = :"groups_test_#{System.unique_integer([:positive])}"

    Req.Test.stub(stub_name, fn conn ->
      case {conn.method, conn.request_path} do
        {"GET", "/groups"} ->
          Req.Test.json(conn, Fixtures.load("groups/list.json"))

        {"GET", "/groups/group-id-1"} ->
          Req.Test.json(conn, Fixtures.load("groups/get.json"))

        {"POST", "/groups"} ->
          conn
          |> Plug.Conn.put_status(201)
          |> Req.Test.json(%{"id" => "new-group-id", "displayName" => "New Group"})

        {"PATCH", "/groups/group-id-1"} ->
          Req.Test.json(conn, %{"id" => "group-id-1", "displayName" => "Updated"})

        {"DELETE", "/groups/group-id-1"} ->
          Plug.Conn.send_resp(conn, 204, "")

        {"GET", "/groups/group-id-1/members"} ->
          Req.Test.json(conn, Fixtures.load("groups/members.json"))

        {"POST", "/groups/group-id-1/members/$ref"} ->
          Plug.Conn.send_resp(conn, 204, "")

        {"DELETE", "/groups/group-id-1/members/user-id-1/$ref"} ->
          Plug.Conn.send_resp(conn, 204, "")

        _ ->
          Plug.Conn.send_resp(conn, 404, "")
      end
    end)

    client = Req.new(plug: {Req.Test, stub_name})
    %{client: client}
  end

  describe "list/1" do
    test "returns list of groups", %{client: client} do
      assert {:ok, %{"value" => groups}} = Groups.list(client: client)
      assert length(groups) == 2
    end
  end

  describe "get/2" do
    test "returns a single group", %{client: client} do
      assert {:ok, group} = Groups.get("group-id-1", client: client)
      assert group["displayName"] == "Engineering"
    end
  end

  describe "create/2" do
    test "creates a group", %{client: client} do
      attrs = %{"displayName" => "New Group", "mailNickname" => "newgroup"}
      assert {:ok, group} = Groups.create(attrs, client: client)
      assert group["id"] == "new-group-id"
    end
  end

  describe "update/3" do
    test "updates a group", %{client: client} do
      assert {:ok, group} =
               Groups.update("group-id-1", %{"displayName" => "Updated"}, client: client)

      assert group["displayName"] == "Updated"
    end
  end

  describe "delete/2" do
    test "deletes a group", %{client: client} do
      assert :ok = Groups.delete("group-id-1", client: client)
    end
  end

  describe "list_members/2" do
    test "returns group members", %{client: client} do
      assert {:ok, %{"value" => members}} = Groups.list_members("group-id-1", client: client)
      assert length(members) == 2
    end
  end

  describe "add_member/3" do
    test "adds a member to the group", %{client: client} do
      assert :ok = Groups.add_member("group-id-1", "user-id-1", client: client)
    end
  end

  describe "remove_member/3" do
    test "removes a member from the group", %{client: client} do
      assert :ok = Groups.remove_member("group-id-1", "user-id-1", client: client)
    end
  end
end
