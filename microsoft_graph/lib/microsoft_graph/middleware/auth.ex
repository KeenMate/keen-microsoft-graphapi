defmodule MicrosoftGraph.Middleware.Auth do
  @moduledoc """
  Req request step that injects the `Authorization: Bearer <token>` header.

  Checks for a per-request `access_token` option first (delegated permissions).
  Falls back to `MicrosoftGraph.TokenStore` using client credentials config.
  If neither is available, halts with a 401 error.
  """

  alias MicrosoftGraph.TokenStore

  @doc """
  Attaches the auth step to a Req request.
  """
  @spec attach(Req.Request.t()) :: Req.Request.t()
  def attach(%Req.Request{} = request) do
    Req.Request.prepend_request_steps(request, microsoft_graph_auth: &add_token/1)
  end

  defp add_token(request) do
    case request.options[:access_token] do
      token when is_binary(token) and token != "" ->
        Req.Request.put_header(request, "authorization", "Bearer #{token}")

      _ ->
        add_token_from_store(request)
    end
  end

  defp add_token_from_store(request) do
    config = request.options[:microsoft_graph_config]

    if config do
      token_store = request.options[:microsoft_graph_token_store] || TokenStore

      case TokenStore.get_token(config, token_store) do
        {:ok, token} ->
          Req.Request.put_header(request, "authorization", "Bearer #{token}")

        {:error, error} ->
          {request, Req.Response.new(status: 401, body: %{"error" => inspect(error)})}
      end
    else
      {request,
       Req.Response.new(
         status: 401,
         body: %{"error" => "No access_token or client credentials config provided"}
       )}
    end
  end
end
