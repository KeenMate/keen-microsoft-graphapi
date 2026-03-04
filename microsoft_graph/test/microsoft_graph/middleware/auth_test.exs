defmodule MicrosoftGraph.Middleware.AuthTest do
  use ExUnit.Case, async: true

  alias MicrosoftGraph.Middleware.Auth

  describe "access_token bypass" do
    test "uses access_token from request options instead of TokenStore" do
      stub_name = :"auth_test_#{System.unique_integer([:positive])}"

      Req.Test.stub(stub_name, fn conn ->
        # Verify the Authorization header was set
        case Plug.Conn.get_req_header(conn, "authorization") do
          ["Bearer my-user-token"] ->
            Req.Test.json(conn, %{"displayName" => "Me"})

          other ->
            conn
            |> Plug.Conn.put_status(401)
            |> Req.Test.json(%{
              "error" => "Expected Bearer my-user-token, got: #{inspect(other)}"
            })
        end
      end)

      client =
        Req.new(plug: {Req.Test, stub_name})
        |> Req.Request.register_options([:access_token])
        |> Auth.attach()

      assert {:ok, %Req.Response{status: 200, body: body}} =
               Req.get(client, url: "/me", access_token: "my-user-token")

      assert body["displayName"] == "Me"
    end

    test "returns 401 when no access_token and no config" do
      stub_name = :"auth_test_noconfig_#{System.unique_integer([:positive])}"

      Req.Test.stub(stub_name, fn conn ->
        Req.Test.json(conn, %{"should" => "not reach"})
      end)

      client =
        Req.new(plug: {Req.Test, stub_name})
        |> Req.Request.register_options([:access_token, :microsoft_graph_config])
        |> Auth.attach()

      assert {:ok, %Req.Response{status: 401}} = Req.get(client, url: "/me")
    end
  end
end
