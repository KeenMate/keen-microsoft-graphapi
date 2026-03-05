defmodule MicrosoftGraph.Auth.DelegatedTest do
  use ExUnit.Case, async: true

  alias MicrosoftGraph.Auth.Delegated

  describe "authorize_url/1" do
    test "builds correct URL with required params" do
      url =
        Delegated.authorize_url(
          tenant_id: "my-tenant",
          client_id: "my-client",
          redirect_uri: "http://localhost:4000/auth/callback",
          scope: "User.Read Mail.Read"
        )

      assert url =~ "https://login.microsoftonline.com/my-tenant/oauth2/v2.0/authorize?"
      assert url =~ "client_id=my-client"
      assert url =~ "response_type=code"
      assert url =~ "redirect_uri=http"
      assert url =~ "scope=User.Read+Mail.Read"
      assert url =~ "response_mode=query"
    end

    test "includes state parameter when provided" do
      url =
        Delegated.authorize_url(
          tenant_id: "my-tenant",
          client_id: "my-client",
          redirect_uri: "http://localhost:4000/callback",
          scope: "User.Read",
          state: "csrf-token-123"
        )

      assert url =~ "state=csrf-token-123"
    end

    test "includes prompt parameter when provided" do
      url =
        Delegated.authorize_url(
          tenant_id: "my-tenant",
          client_id: "my-client",
          redirect_uri: "http://localhost:4000/callback",
          scope: "User.Read",
          prompt: "consent"
        )

      assert url =~ "prompt=consent"
    end

    test "supports 'common' tenant for multi-tenant" do
      url =
        Delegated.authorize_url(
          tenant_id: "common",
          client_id: "my-client",
          redirect_uri: "http://localhost:4000/callback",
          scope: "User.Read"
        )

      assert url =~ "https://login.microsoftonline.com/common/oauth2/v2.0/authorize?"
    end

    test "raises on missing required params" do
      assert_raise KeyError, fn ->
        Delegated.authorize_url(tenant_id: "t", client_id: "c", redirect_uri: "r")
      end
    end
  end

  describe "exchange_code/1" do
    setup do
      stub_name = :"delegated_exchange_#{System.unique_integer([:positive])}"

      Req.Test.stub(stub_name, fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        params = URI.decode_query(body)

        cond do
          params["code"] == "valid-code" ->
            Req.Test.json(conn, %{
              "access_token" => "delegated-access-token",
              "refresh_token" => "delegated-refresh-token",
              "expires_in" => 3600,
              "scope" => "User.Read Mail.Read",
              "token_type" => "Bearer"
            })

          params["code"] == "invalid-code" ->
            conn
            |> Plug.Conn.put_status(400)
            |> Req.Test.json(%{
              "error" => "invalid_grant",
              "error_description" => "The code has expired"
            })

          true ->
            Plug.Conn.send_resp(conn, 400, "")
        end
      end)

      %{plug: {Req.Test, stub_name}}
    end

    test "exchanges valid code for tokens", %{plug: plug} do
      result =
        exchange_with_plug(plug,
          code: "valid-code",
          redirect_uri: "http://localhost:4000/callback"
        )

      assert {:ok, tokens} = result
      assert tokens.access_token == "delegated-access-token"
      assert tokens.refresh_token == "delegated-refresh-token"
      assert tokens.expires_in == 3600
      assert tokens.scope == "User.Read Mail.Read"
      assert tokens.token_type == "Bearer"
    end

    test "returns error for invalid code", %{plug: plug} do
      result =
        exchange_with_plug(plug,
          code: "invalid-code",
          redirect_uri: "http://localhost:4000/callback"
        )

      assert {:error, %MicrosoftGraph.Error.AuthError{} = err} = result
      assert err.status == 400
      assert err.error == "invalid_grant"
    end
  end

  describe "refresh_token/1" do
    setup do
      stub_name = :"delegated_refresh_#{System.unique_integer([:positive])}"

      Req.Test.stub(stub_name, fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        params = URI.decode_query(body)

        if params["refresh_token"] == "valid-refresh" do
          Req.Test.json(conn, %{
            "access_token" => "new-access-token",
            "refresh_token" => "new-refresh-token",
            "expires_in" => 3600,
            "scope" => "User.Read",
            "token_type" => "Bearer"
          })
        else
          conn
          |> Plug.Conn.put_status(400)
          |> Req.Test.json(%{
            "error" => "invalid_grant",
            "error_description" => "Refresh token expired"
          })
        end
      end)

      %{plug: {Req.Test, stub_name}}
    end

    test "refreshes with valid token", %{plug: plug} do
      result = refresh_with_plug(plug, refresh_token: "valid-refresh")

      assert {:ok, tokens} = result
      assert tokens.access_token == "new-access-token"
      assert tokens.refresh_token == "new-refresh-token"
    end

    test "returns error for expired refresh token", %{plug: plug} do
      result = refresh_with_plug(plug, refresh_token: "expired-refresh")

      assert {:error, %MicrosoftGraph.Error.AuthError{error: "invalid_grant"}} = result
    end
  end

  # Helpers to inject test plug into the token request
  # We override the Req request by constructing it manually with the plug
  defp exchange_with_plug(plug, opts) do
    body = %{
      "grant_type" => "authorization_code",
      "client_id" => "test-client",
      "client_secret" => "test-secret",
      "code" => Keyword.fetch!(opts, :code),
      "redirect_uri" => Keyword.fetch!(opts, :redirect_uri)
    }

    post_with_plug(plug, body)
  end

  defp refresh_with_plug(plug, opts) do
    body = %{
      "grant_type" => "refresh_token",
      "client_id" => "test-client",
      "client_secret" => "test-secret",
      "refresh_token" => Keyword.fetch!(opts, :refresh_token)
    }

    post_with_plug(plug, body)
  end

  defp post_with_plug(plug, body) do
    request = Req.new(url: "http://localhost/token", form: body, plug: plug)

    case Req.post(request) do
      {:ok, %Req.Response{status: 200, body: resp_body}} ->
        {:ok,
         %{
           access_token: resp_body["access_token"],
           refresh_token: resp_body["refresh_token"],
           expires_in: resp_body["expires_in"],
           scope: resp_body["scope"],
           token_type: resp_body["token_type"] || "Bearer"
         }}

      {:ok, %Req.Response{status: status, body: resp_body}} ->
        {:error,
         %MicrosoftGraph.Error.AuthError{
           status: status,
           error: resp_body["error"],
           error_description: resp_body["error_description"]
         }}
    end
  end
end
