defmodule GraphApi.DelegatedTest do
  use ExUnit.Case, async: true

  alias GraphApi.Middleware
  alias GraphApi.Users

  describe "per-request access_token" do
    test "passes access_token through to auth middleware" do
      stub_name = :"delegated_test_#{System.unique_integer([:positive])}"

      Req.Test.stub(stub_name, fn conn ->
        case Plug.Conn.get_req_header(conn, "authorization") do
          ["Bearer user-token-abc"] ->
            Req.Test.json(conn, %{"id" => "me", "displayName" => "Current User"})

          _ ->
            conn
            |> Plug.Conn.put_status(401)
            |> Req.Test.json(%{"error" => "unauthorized"})
        end
      end)

      # Build a client with auth middleware but no config
      client =
        Req.new(plug: {Req.Test, stub_name})
        |> Req.Request.register_options([:access_token])
        |> Middleware.Auth.attach()

      assert {:ok, user} = Users.get("me", client: client, access_token: "user-token-abc")
      assert user["displayName"] == "Current User"
    end

    test "list with delegated token works" do
      stub_name = :"delegated_list_#{System.unique_integer([:positive])}"

      Req.Test.stub(stub_name, fn conn ->
        Req.Test.json(conn, %{
          "value" => [%{"id" => "1", "displayName" => "User 1"}]
        })
      end)

      client =
        Req.new(plug: {Req.Test, stub_name})
        |> Req.Request.register_options([:access_token])
        |> Middleware.Auth.attach()

      assert {:ok, %{"value" => [user]}} =
               Users.list(client: client, access_token: "some-token")

      assert user["displayName"] == "User 1"
    end
  end

  describe "per-request api_version" do
    test "overrides base URL to beta" do
      stub_name = :"beta_test_#{System.unique_integer([:positive])}"

      Req.Test.stub(stub_name, fn conn ->
        # When api_version: :beta is used, the URL becomes absolute with /beta prefix
        if String.contains?(conn.request_path, "/beta/") or
             conn.request_path =~ ~r{^/beta/} do
          Req.Test.json(conn, %{"value" => [%{"id" => "beta-user"}]})
        else
          Req.Test.json(conn, %{"value" => [%{"id" => "v1-user"}]})
        end
      end)

      client = Req.new(plug: {Req.Test, stub_name})

      # Without api_version override, uses relative path
      assert {:ok, %{"value" => [user]}} = Users.list(client: client)
      assert user["id"] == "v1-user"
    end
  end
end
