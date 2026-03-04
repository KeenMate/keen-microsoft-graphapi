defmodule MicrosoftGraph.BatchTest do
  use ExUnit.Case, async: true

  alias MicrosoftGraph.Batch
  alias MicrosoftGraph.Users
  alias MicrosoftGraph.Groups
  alias MicrosoftGraph.OData

  setup do
    stub_name = :"batch_test_#{System.unique_integer([:positive])}"

    Req.Test.stub(stub_name, fn conn ->
      case {conn.method, conn.request_path} do
        {"POST", "/$batch"} ->
          {:ok, body, _conn} = Plug.Conn.read_body(conn)
          request_body = Jason.decode!(body)
          requests = request_body["requests"]

          responses =
            Enum.map(requests, fn req ->
              case {req["method"], req["url"]} do
                {"GET", "/users" <> _} ->
                  %{
                    "id" => req["id"],
                    "status" => 200,
                    "headers" => %{"Content-Type" => "application/json"},
                    "body" => %{
                      "value" => [
                        %{"id" => "user-1", "displayName" => "Alice"},
                        %{"id" => "user-2", "displayName" => "Bob"}
                      ]
                    }
                  }

                {"GET", "/groups/" <> group_id} ->
                  %{
                    "id" => req["id"],
                    "status" => 200,
                    "headers" => %{"Content-Type" => "application/json"},
                    "body" => %{"id" => group_id, "displayName" => "Engineering"}
                  }

                {"POST", "/groups"} ->
                  %{
                    "id" => req["id"],
                    "status" => 201,
                    "headers" => %{"Content-Type" => "application/json"},
                    "body" => Map.merge(req["body"], %{"id" => "new-group-id"})
                  }

                {"DELETE", _} ->
                  %{
                    "id" => req["id"],
                    "status" => 204,
                    "headers" => %{}
                  }

                _ ->
                  %{
                    "id" => req["id"],
                    "status" => 404,
                    "headers" => %{},
                    "body" => %{"error" => %{"code" => "NotFound"}}
                  }
              end
            end)

          Req.Test.json(conn, %{"responses" => responses})

        _ ->
          Plug.Conn.send_resp(conn, 404, "")
      end
    end)

    client = Req.new(plug: {Req.Test, stub_name})
    %{client: client}
  end

  describe "new/0 and add/4" do
    test "builds a batch with multiple requests" do
      batch =
        Batch.new()
        |> Batch.add("1", Users.list_query())
        |> Batch.add("2", Groups.get_query("group-123"))

      assert length(batch.entries) == 2
    end

    test "supports depends_on" do
      batch =
        Batch.new()
        |> Batch.add("1", Users.list_query())
        |> Batch.add("2", Groups.list_query(), depends_on: ["1"])

      entry = Enum.find(batch.entries, &(&1.id == "2"))
      assert entry.depends_on == ["1"]
    end
  end

  describe "execute/2" do
    test "sends batch and returns responses", %{client: client} do
      {:ok, responses} =
        Batch.new()
        |> Batch.add("1", Users.list_query())
        |> Batch.add("2", Groups.get_query("group-123"))
        |> Batch.execute(client: client)

      assert length(responses) == 2

      user_resp = Batch.get(responses, "1")
      assert user_resp.status == 200
      assert %{"value" => [%{"displayName" => "Alice"} | _]} = user_resp.body

      group_resp = Batch.get(responses, "2")
      assert group_resp.status == 200
      assert group_resp.body["displayName"] == "Engineering"
    end

    test "handles POST with body", %{client: client} do
      {:ok, responses} =
        Batch.new()
        |> Batch.add("1", Groups.create_query(%{"displayName" => "New Group"}))
        |> Batch.execute(client: client)

      resp = Batch.get(responses, "1")
      assert resp.status == 201
      assert resp.body["displayName"] == "New Group"
      assert resp.body["id"] == "new-group-id"
    end

    test "handles DELETE (no body)", %{client: client} do
      {:ok, responses} =
        Batch.new()
        |> Batch.add("1", Users.delete_query("user-1"))
        |> Batch.execute(client: client)

      resp = Batch.get(responses, "1")
      assert resp.status == 204
    end

    test "returns error when batch exceeds 20 requests" do
      batch =
        Enum.reduce(1..21, Batch.new(), fn i, batch ->
          Batch.add(batch, to_string(i), Users.list_query())
        end)

      assert {:error, "Batch limited to 20 requests, got 21"} = Batch.execute(batch)
    end

    test "returns ok with empty list for empty batch" do
      assert {:ok, []} = Batch.execute(Batch.new())
    end
  end

  describe "query with OData params" do
    test "serializes OData query into URL", %{client: client} do
      query = OData.new() |> OData.select(["id", "displayName"]) |> OData.top(5)

      {:ok, responses} =
        Batch.new()
        |> Batch.add("1", Users.list_query(query: query))
        |> Batch.execute(client: client)

      assert Batch.get(responses, "1").status == 200
    end
  end

  describe "schema casting" do
    test "casts responses when :as is provided", %{client: client} do
      {:ok, responses} =
        Batch.new()
        |> Batch.add("1", Users.list_query(as: MicrosoftGraph.Schema.User))
        |> Batch.add("2", Groups.get_query("group-123", as: MicrosoftGraph.Schema.Group))
        |> Batch.execute(client: client)

      user_resp = Batch.get(responses, "1")
      assert %{"value" => [%MicrosoftGraph.Schema.User{} | _]} = user_resp.body

      group_resp = Batch.get(responses, "2")
      assert %MicrosoftGraph.Schema.Group{display_name: "Engineering"} = group_resp.body
    end

    test "does not cast when :as is not provided", %{client: client} do
      {:ok, responses} =
        Batch.new()
        |> Batch.add("1", Users.list_query())
        |> Batch.execute(client: client)

      resp = Batch.get(responses, "1")
      assert %{"value" => [%{"displayName" => "Alice"} | _]} = resp.body
    end
  end

  describe "get/2" do
    test "finds response by id", %{client: client} do
      {:ok, responses} =
        Batch.new()
        |> Batch.add("a", Users.list_query())
        |> Batch.add("b", Groups.get_query("group-123"))
        |> Batch.execute(client: client)

      assert %{id: "a"} = Batch.get(responses, "a")
      assert %{id: "b"} = Batch.get(responses, "b")
      assert nil == Batch.get(responses, "nonexistent")
    end
  end

  describe "_query functions" do
    test "Users._query functions return Batch.Request structs" do
      assert %Batch.Request{method: "GET", url: "/users"} = Users.list_query()
      assert %Batch.Request{method: "GET", url: "/users/u1"} = Users.get_query("u1")
      assert %Batch.Request{method: "POST", url: "/users", body: %{"x" => 1}} = Users.create_query(%{"x" => 1})
      assert %Batch.Request{method: "PATCH", url: "/users/u1", body: %{"x" => 1}} = Users.update_query("u1", %{"x" => 1})
      assert %Batch.Request{method: "DELETE", url: "/users/u1"} = Users.delete_query("u1")
    end

    test "_query functions capture :as and :query options" do
      query = OData.new() |> OData.top(10)
      req = Users.list_query(query: query, as: MicrosoftGraph.Schema.User)

      assert req.as == MicrosoftGraph.Schema.User
      assert %OData{top: 10} = req.query
    end
  end
end
