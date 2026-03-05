defmodule GraphApi.Auth.Delegated do
  @moduledoc """
  OAuth 2.0 Authorization Code flow for delegated (user) permissions.

  This module handles the three steps of the authorization code flow:

  1. **Build authorize URL** — redirect the user to Microsoft's login page
  2. **Exchange code** — swap the authorization code for access + refresh tokens
  3. **Refresh token** — get a new access token when the current one expires

  ## Example (Phoenix)

      # Step 1: Redirect to Microsoft login
      url = Delegated.authorize_url(
        tenant_id: "your-tenant-id",
        client_id: "your-client-id",
        redirect_uri: "http://localhost:4000/auth/callback",
        scope: "User.Read Mail.Read",
        state: generate_csrf_token()
      )
      redirect(conn, external: url)

      # Step 2: Exchange code in callback
      {:ok, tokens} = Delegated.exchange_code(
        tenant_id: "your-tenant-id",
        client_id: "your-client-id",
        client_secret: "your-client-secret",
        code: params["code"],
        redirect_uri: "http://localhost:4000/auth/callback"
      )
      # tokens.access_token, tokens.refresh_token, tokens.expires_in

      # Step 3: Refresh when expired
      {:ok, tokens} = Delegated.refresh_token(
        tenant_id: "your-tenant-id",
        client_id: "your-client-id",
        client_secret: "your-client-secret",
        refresh_token: stored_refresh_token
      )
  """

  alias GraphApi.Error.AuthError

  @authorize_url_template "https://login.microsoftonline.com/{tenant}/oauth2/v2.0/authorize"
  @token_url_template "https://login.microsoftonline.com/{tenant}/oauth2/v2.0/token"

  @type token_response :: %{
          access_token: String.t(),
          refresh_token: String.t() | nil,
          expires_in: integer(),
          scope: String.t() | nil,
          token_type: String.t()
        }

  @doc """
  Builds the Microsoft OAuth2 authorization URL.

  The user should be redirected to this URL to sign in and grant permissions.

  ## Required Options

  * `:tenant_id` — Azure AD tenant ID (or `"common"` for multi-tenant)
  * `:client_id` — Application (client) ID
  * `:redirect_uri` — URL to redirect back to after login
  * `:scope` — Space-separated permissions (e.g., `"User.Read Mail.Read"`)

  ## Optional Options

  * `:state` — CSRF token for security (strongly recommended)
  * `:response_type` — Default `"code"`
  * `:response_mode` — Default `"query"`
  * `:prompt` — `"login"`, `"consent"`, `"select_account"`, or `"none"`
  """
  @spec authorize_url(keyword()) :: String.t()
  def authorize_url(opts) do
    tenant_id = Keyword.fetch!(opts, :tenant_id)
    client_id = Keyword.fetch!(opts, :client_id)
    redirect_uri = Keyword.fetch!(opts, :redirect_uri)
    scope = Keyword.fetch!(opts, :scope)

    base_url = String.replace(@authorize_url_template, "{tenant}", tenant_id)

    params = %{
      "client_id" => client_id,
      "response_type" => Keyword.get(opts, :response_type, "code"),
      "redirect_uri" => redirect_uri,
      "scope" => scope,
      "response_mode" => Keyword.get(opts, :response_mode, "query")
    }

    params =
      case Keyword.get(opts, :state) do
        nil -> params
        state -> Map.put(params, "state", state)
      end

    params =
      case Keyword.get(opts, :prompt) do
        nil -> params
        prompt -> Map.put(params, "prompt", prompt)
      end

    "#{base_url}?#{URI.encode_query(params)}"
  end

  @doc """
  Exchanges an authorization code for access and refresh tokens.

  ## Required Options

  * `:tenant_id` — Azure AD tenant ID
  * `:client_id` — Application (client) ID
  * `:client_secret` — Application client secret
  * `:code` — The authorization code from the callback
  * `:redirect_uri` — Must match the redirect_uri used in `authorize_url/1`

  ## Optional Options

  * `:scope` — Scope string (optional, defaults to the scope granted)
  """
  @spec exchange_code(keyword()) :: {:ok, token_response()} | {:error, AuthError.t()}
  def exchange_code(opts) do
    tenant_id = Keyword.fetch!(opts, :tenant_id)
    client_id = Keyword.fetch!(opts, :client_id)
    client_secret = Keyword.fetch!(opts, :client_secret)
    code = Keyword.fetch!(opts, :code)
    redirect_uri = Keyword.fetch!(opts, :redirect_uri)

    body = %{
      "grant_type" => "authorization_code",
      "client_id" => client_id,
      "client_secret" => client_secret,
      "code" => code,
      "redirect_uri" => redirect_uri
    }

    body =
      case Keyword.get(opts, :scope) do
        nil -> body
        scope -> Map.put(body, "scope", scope)
      end

    post_token(tenant_id, body)
  end

  @doc """
  Refreshes an access token using a refresh token.

  ## Required Options

  * `:tenant_id` — Azure AD tenant ID
  * `:client_id` — Application (client) ID
  * `:client_secret` — Application client secret
  * `:refresh_token` — The refresh token from a previous token response

  ## Optional Options

  * `:scope` — Scope string (optional)
  """
  @spec refresh_token(keyword()) :: {:ok, token_response()} | {:error, AuthError.t()}
  def refresh_token(opts) do
    tenant_id = Keyword.fetch!(opts, :tenant_id)
    client_id = Keyword.fetch!(opts, :client_id)
    client_secret = Keyword.fetch!(opts, :client_secret)
    refresh_token = Keyword.fetch!(opts, :refresh_token)

    body = %{
      "grant_type" => "refresh_token",
      "client_id" => client_id,
      "client_secret" => client_secret,
      "refresh_token" => refresh_token
    }

    body =
      case Keyword.get(opts, :scope) do
        nil -> body
        scope -> Map.put(body, "scope", scope)
      end

    post_token(tenant_id, body)
  end

  # -- Internal --

  defp post_token(tenant_id, body) do
    url = String.replace(@token_url_template, "{tenant}", tenant_id)
    request = Req.new(url: url, form: body)

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
         %AuthError{
           status: status,
           error: resp_body["error"],
           error_description: resp_body["error_description"]
         }}

      {:error, exception} ->
        {:error,
         %AuthError{
           status: 0,
           error: "request_failed",
           error_description: Exception.message(exception)
         }}
    end
  end
end
