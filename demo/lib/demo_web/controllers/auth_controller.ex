defmodule DemoWeb.AuthController do
  use Phoenix.Controller, formats: [:html]

  alias MicrosoftGraph.Auth.Delegated

  @doc """
  Redirects the user to Microsoft's OAuth login page.
  Reads tenant_id, client_id from session (set by LiveView params).
  """
  def login(conn, _params) do
    tenant_id = get_session(conn, :tenant_id) || System.get_env("AZURE_TENANT_ID", "common")
    client_id = get_session(conn, :client_id) || System.get_env("AZURE_CLIENT_ID", "")

    if client_id == "" do
      conn
      |> put_flash(:error, "Client ID is required. Fill it in the Authentication section first.")
      |> redirect(to: "/")
    else
      state = Base.url_encode64(:crypto.strong_rand_bytes(16))

      redirect_uri = "#{conn.scheme}://#{conn.host}:#{conn.port}/auth/callback"

      url =
        Delegated.authorize_url(
          tenant_id: tenant_id,
          client_id: client_id,
          redirect_uri: redirect_uri,
          scope: "User.Read offline_access",
          state: state,
          prompt: "select_account"
        )

      conn
      |> put_session(:oauth_state, state)
      |> redirect(external: url)
    end
  end

  @doc """
  Handles the OAuth callback from Microsoft.
  Exchanges the authorization code for tokens and stores them in the session.
  """
  def callback(conn, %{"code" => code, "state" => state}) do
    saved_state = get_session(conn, :oauth_state)

    if saved_state == nil or not Plug.Crypto.secure_compare(state, saved_state) do
      conn
      |> put_flash(:error, "Invalid OAuth state. Please try signing in again.")
      |> redirect(to: "/")
    else
      tenant_id = get_session(conn, :tenant_id) || System.get_env("AZURE_TENANT_ID", "common")
      client_id = get_session(conn, :client_id) || System.get_env("AZURE_CLIENT_ID", "")
      client_secret = get_session(conn, :client_secret) || System.get_env("AZURE_CLIENT_SECRET", "")

      redirect_uri = "#{conn.scheme}://#{conn.host}:#{conn.port}/auth/callback"

      case Delegated.exchange_code(
             tenant_id: tenant_id,
             client_id: client_id,
             client_secret: client_secret,
             code: code,
             redirect_uri: redirect_uri
           ) do
        {:ok, tokens} ->
          conn
          |> delete_session(:oauth_state)
          |> put_session(:delegated_access_token, tokens.access_token)
          |> put_session(:delegated_refresh_token, tokens.refresh_token)
          |> put_flash(:info, "Signed in with Microsoft successfully.")
          |> redirect(to: "/")

        {:error, err} ->
          message =
            case err do
              %{error_description: desc} when is_binary(desc) -> desc
              _ -> "Authentication failed"
            end

          conn
          |> delete_session(:oauth_state)
          |> put_flash(:error, "Sign-in failed: #{message}")
          |> redirect(to: "/")
      end
    end
  end

  def callback(conn, %{"error" => error, "error_description" => description}) do
    conn
    |> delete_session(:oauth_state)
    |> put_flash(:error, "Sign-in error: #{error} — #{description}")
    |> redirect(to: "/")
  end

  def callback(conn, _params) do
    conn
    |> put_flash(:error, "Invalid callback response from Microsoft.")
    |> redirect(to: "/")
  end

  @doc """
  Clears delegated auth tokens from the session.
  """
  def logout(conn, _params) do
    conn
    |> delete_session(:delegated_access_token)
    |> delete_session(:delegated_refresh_token)
    |> put_flash(:info, "Signed out.")
    |> redirect(to: "/")
  end
end
