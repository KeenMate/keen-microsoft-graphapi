defmodule MicrosoftGraph.Middleware.ErrorHandling do
  @moduledoc """
  Req response step that parses non-2xx responses into structured error types.
  """

  alias MicrosoftGraph.Error.{ApiError, RateLimitError}

  @doc """
  Attaches the error handling step to a Req request.
  """
  @spec attach(Req.Request.t()) :: Req.Request.t()
  def attach(%Req.Request{} = request) do
    Req.Request.append_response_steps(request, microsoft_graph_errors: &handle_errors/1)
  end

  defp handle_errors({request, %Req.Response{status: status} = response})
       when status >= 200 and status < 300 do
    {request, response}
  end

  defp handle_errors({request, %Req.Response{status: 429} = response}) do
    retry_after = parse_retry_after(response)

    error = %RateLimitError{
      retry_after: retry_after,
      message: "Rate limited by Microsoft Graph API"
    }

    {request, %{response | body: {:error, error}}}
  end

  defp handle_errors({request, %Req.Response{status: status, body: body} = response}) do
    {code, message} = extract_error_info(body)

    error = %ApiError{
      status: status,
      code: code,
      message: message || "HTTP #{status}",
      details: body
    }

    {request, %{response | body: {:error, error}}}
  end

  defp extract_error_info(%{"error" => %{"code" => code, "message" => message}}) do
    {code, message}
  end

  defp extract_error_info(%{"error" => %{"code" => code}}) do
    {code, nil}
  end

  defp extract_error_info(_body), do: {nil, nil}

  defp parse_retry_after(%Req.Response{} = response) do
    case Req.Response.get_header(response, "retry-after") do
      [value | _] ->
        case Integer.parse(value) do
          {seconds, _} -> seconds
          :error -> nil
        end

      _ ->
        nil
    end
  end
end
