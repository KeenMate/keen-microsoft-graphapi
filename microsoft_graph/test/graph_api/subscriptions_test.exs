defmodule GraphApi.SubscriptionsTest do
  use ExUnit.Case, async: true

  alias GraphApi.Subscriptions

  setup do
    stub_name = :"subscriptions_test_#{System.unique_integer([:positive])}"

    Req.Test.stub(stub_name, fn conn ->
      case {conn.method, conn.request_path} do
        {"GET", "/subscriptions"} ->
          Req.Test.json(conn, %{
            "value" => [
              %{
                "id" => "sub-1",
                "resource" => "users",
                "changeType" => "created,updated",
                "notificationUrl" => "https://example.com/webhook",
                "expirationDateTime" => "2025-04-01T00:00:00Z",
                "clientState" => "my-secret"
              },
              %{
                "id" => "sub-2",
                "resource" => "me/messages",
                "changeType" => "created",
                "notificationUrl" => "https://example.com/webhook",
                "expirationDateTime" => "2025-04-01T00:00:00Z"
              }
            ]
          })

        {"GET", "/subscriptions/sub-1"} ->
          Req.Test.json(conn, %{
            "id" => "sub-1",
            "resource" => "users",
            "changeType" => "created,updated",
            "notificationUrl" => "https://example.com/webhook",
            "expirationDateTime" => "2025-04-01T00:00:00Z",
            "clientState" => "my-secret"
          })

        {"POST", "/subscriptions"} ->
          conn
          |> Plug.Conn.put_status(201)
          |> Req.Test.json(%{
            "id" => "new-sub-id",
            "resource" => "users",
            "changeType" => "created,updated,deleted",
            "notificationUrl" => "https://example.com/webhook",
            "expirationDateTime" => "2025-04-01T00:00:00Z"
          })

        {"PATCH", "/subscriptions/sub-1"} ->
          Req.Test.json(conn, %{
            "id" => "sub-1",
            "expirationDateTime" => "2025-05-01T00:00:00Z"
          })

        {"DELETE", "/subscriptions/sub-1"} ->
          Plug.Conn.send_resp(conn, 204, "")

        _ ->
          Plug.Conn.send_resp(conn, 404, "")
      end
    end)

    client = Req.new(plug: {Req.Test, stub_name})
    %{client: client}
  end

  describe "list/1" do
    test "returns list of subscriptions", %{client: client} do
      assert {:ok, %{"value" => subs}} = Subscriptions.list(client: client)
      assert length(subs) == 2
      assert hd(subs)["resource"] == "users"
    end
  end

  describe "get/2" do
    test "returns a single subscription", %{client: client} do
      assert {:ok, sub} = Subscriptions.get("sub-1", client: client)
      assert sub["id"] == "sub-1"
      assert sub["resource"] == "users"
      assert sub["clientState"] == "my-secret"
    end
  end

  describe "create/2" do
    test "creates a subscription", %{client: client} do
      attrs = %{
        "changeType" => "created,updated,deleted",
        "notificationUrl" => "https://example.com/webhook",
        "resource" => "users",
        "expirationDateTime" => "2025-04-01T00:00:00Z"
      }

      assert {:ok, sub} = Subscriptions.create(attrs, client: client)
      assert sub["id"] == "new-sub-id"
      assert sub["changeType"] == "created,updated,deleted"
    end
  end

  describe "renew/3" do
    test "renews a subscription", %{client: client} do
      attrs = %{"expirationDateTime" => "2025-05-01T00:00:00Z"}
      assert {:ok, sub} = Subscriptions.renew("sub-1", attrs, client: client)
      assert sub["id"] == "sub-1"
      assert sub["expirationDateTime"] == "2025-05-01T00:00:00Z"
    end
  end

  describe "delete/2" do
    test "deletes a subscription", %{client: client} do
      assert :ok = Subscriptions.delete("sub-1", client: client)
    end
  end

  describe "batch query variants" do
    test "list_query/1 returns Batch.Request", _context do
      req = Subscriptions.list_query()
      assert %GraphApi.Batch.Request{method: "GET", url: "/subscriptions"} = req
    end

    test "get_query/2 returns Batch.Request", _context do
      req = Subscriptions.get_query("sub-1")
      assert %GraphApi.Batch.Request{method: "GET", url: "/subscriptions/sub-1"} = req
    end

    test "create_query/2 returns Batch.Request", _context do
      attrs = %{"resource" => "users"}
      req = Subscriptions.create_query(attrs)
      assert %GraphApi.Batch.Request{method: "POST", url: "/subscriptions", body: ^attrs} = req
    end

    test "renew_query/3 returns Batch.Request", _context do
      attrs = %{"expirationDateTime" => "2025-05-01T00:00:00Z"}
      req = Subscriptions.renew_query("sub-1", attrs)
      assert %GraphApi.Batch.Request{method: "PATCH", url: "/subscriptions/sub-1", body: ^attrs} = req
    end

    test "delete_query/2 returns Batch.Request", _context do
      req = Subscriptions.delete_query("sub-1")
      assert %GraphApi.Batch.Request{method: "DELETE", url: "/subscriptions/sub-1"} = req
    end
  end
end
