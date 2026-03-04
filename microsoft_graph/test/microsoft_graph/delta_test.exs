defmodule MicrosoftGraph.DeltaTest do
  use ExUnit.Case, async: true

  alias MicrosoftGraph.Delta
  alias MicrosoftGraph.Users
  alias MicrosoftGraph.Groups

  setup do
    stub_name = :"delta_test_#{System.unique_integer([:positive])}"

    Req.Test.stub(stub_name, fn conn ->
      path = conn.request_path
      qs = conn.query_string

      cond do
        # Page 2 — returns deltaLink (final page)
        conn.method == "GET" and path == "/users/delta" and String.contains?(qs, "skiptoken") ->
          Req.Test.json(conn, %{
            "value" => [
              %{"id" => "user-3", "displayName" => "Charlie"}
            ],
            "@odata.deltaLink" => "http://localhost/users/delta?$deltatoken=final123"
          })

        # Delta token — returns changes
        conn.method == "GET" and path == "/users/delta" and String.contains?(qs, "deltatoken") ->
          Req.Test.json(conn, %{
            "value" => [
              %{"id" => "user-2", "displayName" => "Bob Updated"},
              %{"id" => "user-4", "@removed" => %{"reason" => "deleted"}}
            ],
            "@odata.deltaLink" => "http://localhost/users/delta?$deltatoken=next456"
          })

        # Initial delta — returns page 1 with nextLink (catch-all for /users/delta)
        conn.method == "GET" and path == "/users/delta" ->
          Req.Test.json(conn, %{
            "value" => [
              %{"id" => "user-1", "displayName" => "Alice"},
              %{"id" => "user-2", "displayName" => "Bob"}
            ],
            "@odata.nextLink" => "http://localhost/users/delta?$skiptoken=page2"
          })

        # Groups delta — single page
        conn.method == "GET" and path == "/groups/delta" ->
          Req.Test.json(conn, %{
            "value" => [
              %{"id" => "group-1", "displayName" => "Engineering"}
            ],
            "@odata.deltaLink" => "http://localhost/groups/delta?$deltatoken=g1"
          })

        # Group members delta
        conn.method == "GET" and path == "/groups/group-1/members/delta" ->
          Req.Test.json(conn, %{
            "value" => [
              %{"id" => "user-1", "displayName" => "Alice"}
            ],
            "@odata.deltaLink" => "http://localhost/groups/group-1/members/delta?$deltatoken=m1"
          })

        true ->
          Plug.Conn.send_resp(conn, 404, "")
      end
    end)

    client = Req.new(plug: {Req.Test, stub_name})
    %{client: client}
  end

  describe "query/2" do
    test "returns items and nextLink for first page", %{client: client} do
      {:ok, page} = Delta.query("/users/delta", client: client)

      assert length(page.items) == 2
      assert hd(page.items)["displayName"] == "Alice"
      assert page.next_link =~ "skiptoken=page2"
      assert page.delta_link == nil
    end

    test "returns items and deltaLink for final page", %{client: client} do
      {:ok, page} = Delta.query("http://localhost/users/delta?$skiptoken=page2", client: client)

      assert length(page.items) == 1
      assert hd(page.items)["displayName"] == "Charlie"
      assert page.delta_link =~ "deltatoken=final123"
      assert page.next_link == nil
    end

    test "follows deltaLink for incremental changes", %{client: client} do
      {:ok, changes} = Delta.query("http://localhost/users/delta?$deltatoken=final123", client: client)

      assert length(changes.items) == 2

      updated = Enum.find(changes.items, &(&1["id"] == "user-2"))
      assert updated["displayName"] == "Bob Updated"

      removed = Enum.find(changes.items, &(&1["id"] == "user-4"))
      assert removed["@removed"] == %{"reason" => "deleted"}

      assert changes.delta_link =~ "deltatoken=next456"
    end
  end

  describe "collect_all/2" do
    test "follows nextLinks and returns all items with deltaLink", %{client: client} do
      {:ok, result} = Delta.collect_all("/users/delta", client: client)

      assert length(result.items) == 3
      assert Enum.map(result.items, & &1["id"]) == ["user-1", "user-2", "user-3"]
      assert result.delta_link =~ "deltatoken=final123"
      assert result.next_link == nil
    end
  end

  describe "stream/2" do
    test "streams items across pages", %{client: client} do
      {:ok, first_page} = Delta.query("/users/delta", client: client)

      items =
        first_page
        |> Delta.stream(client: client)
        |> Enum.to_list()

      assert length(items) == 3
      assert Enum.map(items, & &1["displayName"]) == ["Alice", "Bob", "Charlie"]
    end
  end

  describe "schema casting" do
    test "casts items with :as option", %{client: client} do
      {:ok, page} = Delta.query("/users/delta", client: client, as: MicrosoftGraph.Schema.User)

      assert [%MicrosoftGraph.Schema.User{display_name: "Alice"} | _] = page.items
    end

    test "does not cast @removed items", %{client: client} do
      {:ok, changes} = Delta.query(
        "http://localhost/users/delta?$deltatoken=final123",
        client: client,
        as: MicrosoftGraph.Schema.User
      )

      updated = Enum.find(changes.items, fn
        %MicrosoftGraph.Schema.User{} -> true
        _ -> false
      end)
      assert %MicrosoftGraph.Schema.User{display_name: "Bob Updated"} = updated

      removed = Enum.find(changes.items, fn
        %{"@removed" => _} -> true
        _ -> false
      end)
      assert removed["@removed"] == %{"reason" => "deleted"}
    end
  end

  describe "convenience functions" do
    test "Users.delta/1", %{client: client} do
      {:ok, page} = Users.delta(client: client)
      assert length(page.items) == 2
    end

    test "Groups.delta/1", %{client: client} do
      {:ok, page} = Groups.delta(client: client)
      assert hd(page.items)["displayName"] == "Engineering"
    end

    test "Groups.members_delta/2", %{client: client} do
      {:ok, page} = Groups.members_delta("group-1", client: client)
      assert hd(page.items)["displayName"] == "Alice"
    end
  end
end
