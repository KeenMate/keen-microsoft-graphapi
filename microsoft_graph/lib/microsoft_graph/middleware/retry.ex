defmodule MicrosoftGraph.Middleware.Retry do
  @moduledoc """
  Req step that handles retries for 429 (Too Many Requests) responses.

  Uses the `Retry-After` header to determine wait time. Falls back to
  exponential backoff. Maximum 3 retries.
  """

  @max_retries 3
  @default_retry_delay_ms 1_000

  @doc """
  Attaches the retry step to a Req request.
  """
  @spec attach(Req.Request.t()) :: Req.Request.t()
  def attach(%Req.Request{} = request) do
    request
    |> Req.Request.register_options([:microsoft_graph_retry_count])
    |> Req.Request.append_response_steps(microsoft_graph_retry: &maybe_retry/1)
  end

  defp maybe_retry({request, %Req.Response{status: 429} = response}) do
    retry_count = request.options[:microsoft_graph_retry_count] || 0

    if retry_count < @max_retries do
      delay = compute_delay(response, retry_count)
      Process.sleep(delay)

      updated_request =
        Req.Request.put_option(request, :microsoft_graph_retry_count, retry_count + 1)

      {updated_request, Req.Request.run!(updated_request)}
    else
      {request, response}
    end
  end

  defp maybe_retry({request, response}) do
    {request, response}
  end

  defp compute_delay(response, retry_count) do
    case Req.Response.get_header(response, "retry-after") do
      [value | _] ->
        case Integer.parse(value) do
          {seconds, _} -> seconds * 1_000
          :error -> exponential_backoff(retry_count)
        end

      _ ->
        exponential_backoff(retry_count)
    end
  end

  defp exponential_backoff(retry_count) do
    @default_retry_delay_ms * Integer.pow(2, retry_count)
  end
end
