defmodule MicrosoftGraph.Auth do
  @moduledoc """
  Token acquisition for Microsoft Entra ID (Azure AD) using the client credentials flow.

  Acquires OAuth 2.0 tokens by POSTing to the Entra ID token endpoint.
  Tokens are typically managed by `MicrosoftGraph.TokenStore` rather than
  calling this module directly.
  """

  alias MicrosoftGraph.Config
  alias MicrosoftGraph.Error.AuthError

  @token_url_template "https://login.microsoftonline.com/{tenant}/oauth2/v2.0/token"

  @type token_response :: %{
          access_token: String.t(),
          expires_in: integer(),
          acquired_at: integer()
        }

  @doc """
  Acquires an access token using the client credentials flow.

  Returns `{:ok, token_response}` on success or `{:error, %AuthError{}}` on failure.
  """
  @spec acquire_token(Config.t()) :: {:ok, token_response()} | {:error, AuthError.t()}
  def acquire_token(%Config{} = config) do
    url = token_url(config.tenant_id)

    body = %{
      "grant_type" => "client_credentials",
      "client_id" => config.client_id,
      "client_secret" => config.client_secret,
      "scope" => config.scope
    }

    request = Req.new(url: url, form: body)

    case Req.post(request) do
      {:ok, %Req.Response{status: 200, body: body}} ->
        {:ok,
         %{
           access_token: body["access_token"],
           expires_in: body["expires_in"],
           acquired_at: System.system_time(:second)
         }}

      {:ok, %Req.Response{status: status, body: body}} ->
        {:error,
         %AuthError{
           status: status,
           error: body["error"],
           error_description: body["error_description"]
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

  @doc """
  Checks whether a token has expired or will expire within the buffer period.

  The default buffer is 300 seconds (5 minutes) to allow proactive refresh.
  """
  @spec token_expired?(token_response(), integer()) :: boolean()
  def token_expired?(token, buffer_seconds \\ 300) do
    expires_at = token.acquired_at + token.expires_in - buffer_seconds
    System.system_time(:second) >= expires_at
  end

  @doc false
  def token_url(tenant_id) do
    String.replace(@token_url_template, "{tenant}", tenant_id)
  end
end
