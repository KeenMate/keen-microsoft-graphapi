defmodule GraphApi.Integration.GraphApiTest do
  @moduledoc """
  Integration tests against a real Microsoft Graph API tenant.

  Requires `.env.test` with valid Azure credentials.
  Run with: mix test --include integration

  Required Application permissions (with admin consent):
    - User.ReadWrite.All
    - Group.ReadWrite.All
    - GroupMember.ReadWrite.All
  """
  use ExUnit.Case

  alias GraphApi.{Groups, OData, Pagination, Users}

  @moduletag :integration
  @moduletag timeout: :timer.minutes(10)

  # Azure AD needs time to propagate writes. This retries a function
  # until it succeeds or we run out of attempts.
  defp wait_for(fun, attempts \\ 5, delay_ms \\ 15_000) do
    case fun.() do
      {:ok, _} = result ->
        result

      :ok ->
        :ok

      {:error, _} when attempts > 1 ->
        Process.sleep(delay_ms)
        wait_for(fun, attempts - 1, delay_ms)

      other ->
        other
    end
  end

  setup_all do
    tenant_id = System.get_env("AZURE_TENANT_ID")
    client_id = System.get_env("AZURE_CLIENT_ID")
    client_secret = System.get_env("AZURE_CLIENT_SECRET")
    test_user_id = System.get_env("AZURE_TEST_USER_ID")

    if is_nil(tenant_id) or is_nil(client_id) or is_nil(client_secret) do
      raise """
      Missing Azure credentials for integration tests.
      Copy .env.test.example to .env.test and fill in your values.
      """
    end

    domain =
      if test_user_id && String.contains?(test_user_id, "@") do
        test_user_id |> String.split("@") |> List.last()
      else
        raise """
        AZURE_TEST_USER_ID must be set to a UPN (user@domain.com) in .env.test.
        The domain is used to create test users.
        """
      end

    config =
      GraphApi.Config.new!(
        tenant_id: tenant_id,
        client_id: client_id,
        client_secret: client_secret
      )

    client = GraphApi.Client.new(config: config)

    %{
      client: client,
      config: config,
      test_user_id: test_user_id,
      domain: domain
    }
  end

  # ── Auth ──────────────────────────────────────────────────────────

  describe "auth" do
    test "acquires token successfully", %{config: config} do
      assert {:ok, token} = GraphApi.Auth.acquire_token(config)
      assert is_binary(token.access_token)
      assert token.expires_in > 0
    end
  end

  # ── Users: Read ───────────────────────────────────────────────────

  describe "users - read" do
    test "list users", %{client: client} do
      assert {:ok, %{"value" => users}} = Users.list(client: client)
      assert is_list(users)
      IO.puts("  Found #{length(users)} users")
    end

    test "list with $select, $top, $orderby", %{client: client} do
      query =
        OData.new()
        |> OData.select(["id", "displayName", "mail"])
        |> OData.top(5)
        |> OData.orderby("displayName")

      assert {:ok, %{"value" => users}} = Users.list(client: client, query: query)
      assert length(users) <= 5

      if users != [] do
        user = hd(users)
        assert Map.has_key?(user, "id")
        assert Map.has_key?(user, "displayName")
        IO.puts("  First user: #{user["displayName"]}")
      end
    end

    test "list with $filter", %{client: client} do
      query = OData.new() |> OData.filter("accountEnabled eq true") |> OData.top(3)
      assert {:ok, %{"value" => users}} = Users.list(client: client, query: query)
      assert is_list(users)
      IO.puts("  Active users (top 3): #{length(users)}")
    end

    test "get user by UPN", %{client: client, test_user_id: user_id} do
      assert {:ok, user} = Users.get(user_id, client: client)
      assert is_binary(user["id"])
      IO.puts("  Got user: #{user["displayName"]}")
    end

    test "get user with $select", %{client: client, test_user_id: user_id} do
      query = OData.new() |> OData.select(["id", "displayName"])
      assert {:ok, user} = Users.get(user_id, client: client, query: query)
      assert Map.has_key?(user, "id")
      assert Map.has_key?(user, "displayName")
    end

    test "list direct reports", %{client: client, test_user_id: user_id} do
      assert {:ok, %{"value" => reports}} = Users.list_direct_reports(user_id, client: client)
      assert is_list(reports)
      IO.puts("  Direct reports: #{length(reports)}")
    end

    test "list member of", %{client: client, test_user_id: user_id} do
      assert {:ok, %{"value" => memberships}} = Users.list_member_of(user_id, client: client)
      assert is_list(memberships)
      IO.puts("  Member of: #{length(memberships)} groups/roles")
    end
  end

  # ── Users: CRUD ───────────────────────────────────────────────────

  describe "users - create, update, delete" do
    test "full lifecycle", %{client: client, domain: domain} do
      unique = System.unique_integer([:positive])
      upn = "testuser.#{unique}@#{domain}"

      # Create
      attrs = %{
        "accountEnabled" => true,
        "displayName" => "Integration Test User #{unique}",
        "mailNickname" => "testuser#{unique}",
        "userPrincipalName" => upn,
        "passwordProfile" => %{
          "forceChangePasswordNextSignIn" => true,
          "password" => "Test1234!@#$pass"
        }
      }

      assert {:ok, created} = Users.create(attrs, client: client)
      assert is_binary(created["id"])
      user_id = created["id"]
      IO.puts("  Created user: #{created["displayName"]} (#{upn})")

      # Read back (retry — Azure needs time to propagate)
      assert {:ok, fetched} = wait_for(fn -> Users.get(user_id, client: client) end)
      assert fetched["userPrincipalName"] == upn
      IO.puts("  Read back OK")

      # Update (PATCH returns 204 No Content = :ok)
      assert :ok =
               Users.update(user_id, %{"jobTitle" => "Integration Tester"}, client: client)

      Process.sleep(30_000)

      {:ok, refreshed} = Users.get(user_id, client: client)
      assert refreshed["jobTitle"] == "Integration Tester"
      IO.puts("  Updated jobTitle to: #{refreshed["jobTitle"]}")

      # Delete
      assert :ok = Users.delete(user_id, client: client)
      IO.puts("  Deleted user: #{user_id}")
    end
  end

  # ── Groups: Read ──────────────────────────────────────────────────

  describe "groups - read" do
    test "list groups", %{client: client} do
      assert {:ok, %{"value" => groups}} = Groups.list(client: client)
      assert is_list(groups)
      IO.puts("  Found #{length(groups)} groups")
    end

    test "list with $select and $top", %{client: client} do
      query = OData.new() |> OData.select(["id", "displayName"]) |> OData.top(5)
      assert {:ok, %{"value" => groups}} = Groups.list(client: client, query: query)
      assert length(groups) <= 5
    end

    test "get group by ID", %{client: client} do
      {:ok, %{"value" => groups}} =
        Groups.list(client: client, query: OData.new() |> OData.top(1))

      if groups != [] do
        group_id = hd(groups)["id"]
        assert {:ok, group} = Groups.get(group_id, client: client)
        assert group["id"] == group_id
        IO.puts("  Got group: #{group["displayName"]}")
      end
    end

    test "list group members", %{client: client} do
      {:ok, %{"value" => groups}} =
        Groups.list(client: client, query: OData.new() |> OData.top(1))

      if groups != [] do
        group_id = hd(groups)["id"]
        assert {:ok, %{"value" => members}} = Groups.list_members(group_id, client: client)
        assert is_list(members)
        IO.puts("  Group '#{hd(groups)["displayName"]}' has #{length(members)} members")
      end
    end
  end

  # ── Groups: CRUD + Members ────────────────────────────────────────

  describe "groups - create, update, delete, members" do
    test "full lifecycle with member management", %{
      client: client,
      test_user_id: test_user_id
    } do
      unique = System.unique_integer([:positive])

      # Create group
      attrs = %{
        "displayName" => "Integration Test Group #{unique}",
        "mailNickname" => "testgroup#{unique}",
        "description" => "Created by integration test",
        "groupTypes" => [],
        "mailEnabled" => false,
        "securityEnabled" => true
      }

      assert {:ok, created} = Groups.create(attrs, client: client)
      assert is_binary(created["id"])
      group_id = created["id"]
      IO.puts("  Created group: #{created["displayName"]}")

      # Read back (retry — groups take longer to propagate)
      assert {:ok, fetched} = wait_for(fn -> Groups.get(group_id, client: client) end)
      assert fetched["displayName"] =~ "Integration Test Group"
      IO.puts("  Read back OK")

      # Update (PATCH returns 204 No Content = :ok)
      assert :ok =
               Groups.update(group_id, %{"description" => "Updated by test"}, client: client)

      Process.sleep(30_000)

      {:ok, refreshed} = Groups.get(group_id, client: client)
      assert refreshed["description"] == "Updated by test"
      IO.puts("  Updated description")

      # Get the test user's object ID for member operations
      {:ok, user} = Users.get(test_user_id, client: client)
      user_object_id = user["id"]

      # Add member
      assert :ok = Groups.add_member(group_id, user_object_id, client: client)
      IO.puts("  Added #{test_user_id} as member")

      # Verify member (retry — member propagation)
      assert {:ok, %{"value" => members}} =
               wait_for(fn ->
                 case Groups.list_members(group_id, client: client) do
                   {:ok, %{"value" => m}} = result ->
                     if Enum.any?(m, &(&1["id"] == user_object_id)),
                       do: result,
                       else: {:error, :not_yet}

                   other ->
                     other
                 end
               end)

      member_ids = Enum.map(members, & &1["id"])
      assert user_object_id in member_ids
      IO.puts("  Verified: user is in members list")

      # Remove member (wait for member addition to fully propagate)
      Process.sleep(60_000)
      assert :ok = Groups.remove_member(group_id, user_object_id, client: client)
      IO.puts("  Removed member")

      Process.sleep(30_000)

      # Verify removed
      {:ok, %{"value" => members_after}} = Groups.list_members(group_id, client: client)
      member_ids_after = Enum.map(members_after, & &1["id"])
      refute user_object_id in member_ids_after
      IO.puts("  Verified: user removed from members")

      # Delete group
      assert :ok = Groups.delete(group_id, client: client)
      IO.puts("  Deleted group: #{group_id}")
    end
  end

  # ── Pagination ────────────────────────────────────────────────────

  describe "pagination" do
    test "stream users across pages", %{client: client} do
      query = OData.new() |> OData.top(2)
      {:ok, first_page} = Users.list(client: client, query: query)

      all_users =
        Pagination.stream(first_page, client: client)
        |> Enum.take(10)

      assert is_list(all_users)
      IO.puts("  Streamed #{length(all_users)} users (max 10)")
    end

    test "collect all groups", %{client: client} do
      query = OData.new() |> OData.top(2)
      {:ok, first_page} = Groups.list(client: client, query: query)

      {:ok, all_groups} = Pagination.collect_all(first_page, client: client)
      assert is_list(all_groups)
      IO.puts("  Collected #{length(all_groups)} groups total")
    end
  end
end
