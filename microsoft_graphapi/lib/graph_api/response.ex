defmodule GraphApi.Response do
  @moduledoc """
  Normalizes Microsoft Graph API responses into consistent `{:ok, body}` or `{:error, error}` tuples.
  """

  alias GraphApi.Error.ApiError

  @doc """
  Normalizes a Req response into an ok/error tuple.

  - 2xx with a body returns `{:ok, body}`
  - 202 (Accepted) with empty body returns `:ok`
  - 204 (No Content) returns `:ok`
  - Error structs in the body (set by ErrorHandling middleware) are passed through
  - Non-2xx responses are wrapped in `ApiError`
  - Transport errors return `{:error, exception}`
  """
  @spec normalize({:ok, Req.Response.t()} | {:error, Exception.t()}) ::
          {:ok, term()} | :ok | {:error, term()}
  def normalize({:ok, %Req.Response{status: 204}}) do
    :ok
  end

  def normalize({:ok, %Req.Response{status: 202, body: body}}) when body in ["", nil] do
    :ok
  end

  def normalize({:ok, %Req.Response{status: status, body: {:error, _} = error}})
      when status >= 400 do
    error
  end

  def normalize({:ok, %Req.Response{status: status, body: body}})
      when status >= 200 and status < 300 do
    {:ok, body}
  end

  def normalize({:ok, %Req.Response{body: {:error, _} = error}}) do
    error
  end

  def normalize({:ok, %Req.Response{status: status, body: body}}) when status >= 400 do
    {code, message} = extract_error_info(body)

    {:error,
     %ApiError{
       status: status,
       code: code,
       message: message || "HTTP #{status}",
       details: body
     }}
  end

  def normalize({:error, exception}) do
    {:error, exception}
  end

  defp extract_error_info(%{"error" => %{"code" => code, "message" => message}}) do
    {code, message}
  end

  defp extract_error_info(%{"error" => %{"code" => code}}) do
    {code, nil}
  end

  defp extract_error_info(_body), do: {nil, nil}
end
