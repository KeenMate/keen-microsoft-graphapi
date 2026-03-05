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

        {"GET", "/groups/group-id-1/owners"} ->
          Req.Test.json(conn, %{"value" => [%{"id" => "owner-1"}]})

        {"POST", "/groups/group-id-1/owners/$ref"} ->
          Plug.Conn.send_resp(conn, 204, "")

        {"DELETE", "/groups/group-id-1/owners/owner-1/$ref"} ->
          Plug.Conn.send_resp(conn, 204, "")

        {"GET", "/groups/group-id-1/transitiveMembers"} ->
          Req.Test.json(conn, %{"value" => [%{"id" => "user-1"}, %{"id" => "user-2"}]})

        {"GET", "/groups/group-id-1/memberOf"} ->
          Req.Test.json(conn, %{"value" => [%{"id" => "parent-group-1"}]})

        {"POST", "/groups/group-id-1/assignLicense"} ->
          Req.Test.json(conn, %{"id" => "group-id-1"})

        {"POST", "/groups/group-id-1/renew"} ->
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

  describe "list_owners/2" do
    test "returns group owners", %{client: client} do
      assert {:ok, %{"value" => owners}} = Groups.list_owners("group-id-1", client: client)
      assert length(owners) == 1
      assert hd(owners)["id"] == "owner-1"
    end
  end

  describe "add_owner/3" do
    test "adds an owner to the group", %{client: client} do
      assert :ok = Groups.add_owner("group-id-1", "owner-1", client: client)
    end
  end

  describe "remove_owner/3" do
    test "removes an owner from the group", %{client: client} do
      assert :ok = Groups.remove_owner("group-id-1", "owner-1", client: client)
    end
  end

  describe "list_transitive_members/2" do
    test "returns transitive members", %{client: client} do
      assert {:ok, %{"value" => members}} = Groups.list_transitive_members("group-id-1", client: client)
      assert length(members) == 2
    end
  end

  describe "list_member_of/2" do
    test "returns groups this group is a member of", %{client: client} do
      assert {:ok, %{"value" => groups}} = Groups.list_member_of("group-id-1", client: client)
      assert length(groups) == 1
      assert hd(groups)["id"] == "parent-group-1"
    end
  end

  describe "assign_license/3" do
    test "assigns licenses to a group", %{client: client} do
      attrs = %{"addLicenses" => [%{"skuId" => "sku-1"}], "removeLicenses" => []}
      assert {:ok, group} = Groups.assign_license("group-id-1", attrs, client: client)
      assert group["id"] == "group-id-1"
    end
  end

  describe "renew/2" do
    test "renews a group", %{client: client} do
      assert :ok = Groups.renew("group-id-1", client: client)
    end
  end
end
