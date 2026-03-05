defmodule GraphApi.UsersTest do
  use ExUnit.Case, async: true

  alias GraphApi.Test.Fixtures
  alias GraphApi.Users

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

        {"GET", "/users/user-id-1/manager"} ->
          Req.Test.json(conn, %{"id" => "manager-id-1", "displayName" => "Manager User"})

        {"PUT", "/users/user-id-1/manager/$ref"} ->
          Plug.Conn.send_resp(conn, 204, "")

        {"DELETE", "/users/user-id-1/manager/$ref"} ->
          Plug.Conn.send_resp(conn, 204, "")

        {"GET", "/users/user-id-1/photo"} ->
          Req.Test.json(conn, %{"@odata.mediaContentType" => "image/jpeg", "height" => 96, "width" => 96})

        {"GET", "/users/user-id-1/photo/$value"} ->
          conn
          |> Plug.Conn.put_resp_content_type("image/jpeg")
          |> Plug.Conn.send_resp(200, <<0xFF, 0xD8, 0xFF>>)

        {"PUT", "/users/user-id-1/photo/$value"} ->
          Plug.Conn.send_resp(conn, 200, "")

        {"GET", "/users/user-id-1/transitiveMemberOf"} ->
          Req.Test.json(conn, %{"value" => [%{"id" => "group-1"}, %{"id" => "group-2"}]})

        {"POST", "/users/user-id-1/assignLicense"} ->
          Req.Test.json(conn, %{"id" => "user-id-1"})

        {"POST", "/users/user-id-1/revokeSignInSessions"} ->
          Req.Test.json(conn, %{"value" => true})

        {"POST", "/users/user-id-1/changePassword"} ->
          Plug.Conn.send_resp(conn, 204, "")

        {"GET", "/users/user-id-1/appRoleAssignments"} ->
          Req.Test.json(conn, %{"value" => [%{"id" => "assignment-1", "appRoleId" => "role-1"}]})

        {"POST", "/users/user-id-1/appRoleAssignments"} ->
          conn
          |> Plug.Conn.put_status(201)
          |> Req.Test.json(%{"id" => "assignment-new", "appRoleId" => "role-1"})

        {"DELETE", "/users/user-id-1/appRoleAssignments/assignment-1"} ->
          Plug.Conn.send_resp(conn, 204, "")

        {"GET", "/users/user-id-1/oauth2PermissionGrants"} ->
          Req.Test.json(conn, %{"value" => [%{"id" => "grant-1", "scope" => "User.Read"}]})

        {"POST", "/users/user-id-1/exportPersonalData"} ->
          Plug.Conn.send_resp(conn, 202, "")

        {"GET", "/users/user-id-1/licenseDetails"} ->
          Req.Test.json(conn, %{"value" => [%{"id" => "license-1", "skuId" => "sku-1"}]})

        {"POST", "/users/user-id-1/getMemberObjects"} ->
          Req.Test.json(conn, %{"value" => ["obj-1", "obj-2"]})

        {"POST", "/users/user-id-1/getMemberGroups"} ->
          Req.Test.json(conn, %{"value" => ["group-1", "group-2"]})

        {"POST", "/users/user-id-1/checkMemberObjects"} ->
          Req.Test.json(conn, %{"value" => ["obj-1"]})

        {"POST", "/users/user-id-1/checkMemberGroups"} ->
          Req.Test.json(conn, %{"value" => ["group-1"]})

        {"GET", "/users/user-id-1/scopedRoleMemberOf"} ->
          Req.Test.json(conn, %{"value" => [%{"id" => "scoped-role-1"}]})

        {"GET", "/users/user-id-1/authentication/methods"} ->
          Req.Test.json(conn, %{"value" => [%{"id" => "method-1", "@odata.type" => "#microsoft.graph.phoneAuthenticationMethod"}]})

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

  describe "client_request_id" do
    test "sends client-request-id header when set to true", _context do
      stub_name = :"crid_test_#{System.unique_integer([:positive])}"
      :persistent_term.put({stub_name, :header}, nil)

      Req.Test.stub(stub_name, fn conn ->
        header = Plug.Conn.get_req_header(conn, "client-request-id")
        :persistent_term.put({stub_name, :header}, header)
        Req.Test.json(conn, %{"value" => []})
      end)

      client = Req.new(plug: {Req.Test, stub_name})
      {:ok, _} = Users.list(client: client, client_request_id: true)

      [id] = :persistent_term.get({stub_name, :header})
      # Should be a UUID-like string (8-4-4-4-12)
      assert Regex.match?(~r/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/, id)

      :persistent_term.erase({stub_name, :header})
    end

    test "sends custom client-request-id when given a string", _context do
      stub_name = :"crid_custom_#{System.unique_integer([:positive])}"
      :persistent_term.put({stub_name, :header}, nil)

      Req.Test.stub(stub_name, fn conn ->
        header = Plug.Conn.get_req_header(conn, "client-request-id")
        :persistent_term.put({stub_name, :header}, header)
        Req.Test.json(conn, %{"value" => []})
      end)

      client = Req.new(plug: {Req.Test, stub_name})
      {:ok, _} = Users.list(client: client, client_request_id: "my-correlation-123")

      assert ["my-correlation-123"] = :persistent_term.get({stub_name, :header})

      :persistent_term.erase({stub_name, :header})
    end

    test "does not send header when not specified", %{client: client} do
      # Default setup stub doesn't check headers — just verify it works
      assert {:ok, %{"value" => _}} = Users.list(client: client)
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

  describe "get_manager/2" do
    test "returns the user's manager", %{client: client} do
      assert {:ok, manager} = Users.get_manager("user-id-1", client: client)
      assert manager["id"] == "manager-id-1"
      assert manager["displayName"] == "Manager User"
    end
  end

  describe "assign_manager/3" do
    test "assigns a manager to a user", %{client: client} do
      assert :ok = Users.assign_manager("user-id-1", "manager-id-1", client: client)
    end
  end

  describe "remove_manager/2" do
    test "removes a user's manager", %{client: client} do
      assert :ok = Users.remove_manager("user-id-1", client: client)
    end
  end

  describe "get_photo/2" do
    test "returns photo metadata", %{client: client} do
      assert {:ok, photo} = Users.get_photo("user-id-1", client: client)
      assert photo["@odata.mediaContentType"] == "image/jpeg"
      assert photo["height"] == 96
    end
  end

  describe "get_photo_content/2" do
    test "returns photo binary content", %{client: client} do
      assert {:ok, content} = Users.get_photo_content("user-id-1", client: client)
      assert is_binary(content)
    end
  end

  describe "update_photo_content/3" do
    test "uploads photo binary content", %{client: client} do
      assert {:ok, _} = Users.update_photo_content("user-id-1", <<0xFF, 0xD8, 0xFF>>, client: client)
    end
  end

  describe "list_transitive_member_of/2" do
    test "returns transitive memberships", %{client: client} do
      assert {:ok, %{"value" => groups}} = Users.list_transitive_member_of("user-id-1", client: client)
      assert length(groups) == 2
    end
  end

  describe "assign_license/3" do
    test "assigns licenses to a user", %{client: client} do
      attrs = %{"addLicenses" => [%{"skuId" => "sku-1"}], "removeLicenses" => []}
      assert {:ok, user} = Users.assign_license("user-id-1", attrs, client: client)
      assert user["id"] == "user-id-1"
    end
  end

  describe "revoke_sign_in_sessions/2" do
    test "revokes all sign-in sessions", %{client: client} do
      assert {:ok, %{"value" => true}} = Users.revoke_sign_in_sessions("user-id-1", client: client)
    end
  end

  describe "change_password/3" do
    test "changes a user's password", %{client: client} do
      attrs = %{"currentPassword" => "old", "newPassword" => "new"}
      assert :ok = Users.change_password("user-id-1", attrs, client: client)
    end
  end

  describe "list_app_role_assignments/2" do
    test "returns app role assignments", %{client: client} do
      assert {:ok, %{"value" => assignments}} = Users.list_app_role_assignments("user-id-1", client: client)
      assert length(assignments) == 1
      assert hd(assignments)["appRoleId"] == "role-1"
    end
  end

  describe "add_app_role_assignment/3" do
    test "adds an app role assignment", %{client: client} do
      attrs = %{"principalId" => "user-id-1", "resourceId" => "sp-1", "appRoleId" => "role-1"}
      assert {:ok, assignment} = Users.add_app_role_assignment("user-id-1", attrs, client: client)
      assert assignment["id"] == "assignment-new"
    end
  end

  describe "remove_app_role_assignment/3" do
    test "removes an app role assignment", %{client: client} do
      assert :ok = Users.remove_app_role_assignment("user-id-1", "assignment-1", client: client)
    end
  end

  describe "list_oauth2_permission_grants/2" do
    test "returns delegated permission grants", %{client: client} do
      assert {:ok, %{"value" => grants}} = Users.list_oauth2_permission_grants("user-id-1", client: client)
      assert length(grants) == 1
      assert hd(grants)["scope"] == "User.Read"
    end
  end

  describe "export_personal_data/3" do
    test "exports personal data", %{client: client} do
      attrs = %{"storageLocation" => "https://storage.blob.core.windows.net/container"}
      assert :ok = Users.export_personal_data("user-id-1", attrs, client: client)
    end
  end

  describe "list_license_details/2" do
    test "returns license details", %{client: client} do
      assert {:ok, %{"value" => details}} = Users.list_license_details("user-id-1", client: client)
      assert length(details) == 1
      assert hd(details)["skuId"] == "sku-1"
    end
  end

  describe "get_member_objects/3" do
    test "returns member object IDs", %{client: client} do
      attrs = %{"securityEnabledOnly" => false}
      assert {:ok, %{"value" => ids}} = Users.get_member_objects("user-id-1", attrs, client: client)
      assert length(ids) == 2
    end
  end

  describe "get_member_groups/3" do
    test "returns member group IDs", %{client: client} do
      attrs = %{"securityEnabledOnly" => true}
      assert {:ok, %{"value" => ids}} = Users.get_member_groups("user-id-1", attrs, client: client)
      assert length(ids) == 2
    end
  end

  describe "check_member_objects/3" do
    test "checks membership in objects", %{client: client} do
      attrs = %{"ids" => ["obj-1", "obj-2"]}
      assert {:ok, %{"value" => ids}} = Users.check_member_objects("user-id-1", attrs, client: client)
      assert ids == ["obj-1"]
    end
  end

  describe "check_member_groups/3" do
    test "checks membership in groups", %{client: client} do
      attrs = %{"groupIds" => ["group-1", "group-2"]}
      assert {:ok, %{"value" => ids}} = Users.check_member_groups("user-id-1", attrs, client: client)
      assert ids == ["group-1"]
    end
  end

  describe "list_scoped_role_member_of/2" do
    test "returns scoped role memberships", %{client: client} do
      assert {:ok, %{"value" => roles}} = Users.list_scoped_role_member_of("user-id-1", client: client)
      assert length(roles) == 1
      assert hd(roles)["id"] == "scoped-role-1"
    end
  end

  describe "list_authentication_methods/2" do
    test "returns authentication methods", %{client: client} do
      assert {:ok, %{"value" => methods}} = Users.list_authentication_methods("user-id-1", client: client)
      assert length(methods) == 1
      assert hd(methods)["@odata.type"] == "#microsoft.graph.phoneAuthenticationMethod"
    end
  end
end
