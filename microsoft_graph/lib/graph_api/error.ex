defmodule GraphApi.Error do
  @moduledoc """
  Error types for Microsoft Graph API responses.
  """

  defmodule ApiError do
    @moduledoc """
    Represents a non-2xx response from the Microsoft Graph API.

    ## Fields

    * `:status` - HTTP status code
    * `:code` - Graph API error code (e.g., "Request_ResourceNotFound")
    * `:message` - Human-readable error message
    * `:details` - Raw error response body
    """
    defexception [:status, :code, :message, :details]

    @type t :: %__MODULE__{
            status: integer(),
            code: String.t() | nil,
            message: String.t(),
            details: map() | nil
          }

    @impl true
    def message(%__MODULE__{status: status, code: code, message: msg}) do
      parts = ["Graph API error (#{status})"]
      parts = if code, do: parts ++ ["code=#{code}"], else: parts
      parts = if msg, do: parts ++ [msg], else: parts
      Enum.join(parts, ": ")
    end
  end

  defmodule AuthError do
    @moduledoc """
    Represents an authentication/authorization error from Entra ID.

    ## Fields

    * `:status` - HTTP status code
    * `:error` - OAuth error code (e.g., "invalid_client")
    * `:error_description` - Human-readable error description
    """
    defexception [:status, :error, :error_description]

    @type t :: %__MODULE__{
            status: integer(),
            error: String.t() | nil,
            error_description: String.t() | nil
          }

    @impl true
    def message(%__MODULE__{status: status, error: error, error_description: desc}) do
      parts = ["Auth error (#{status})"]
      parts = if error, do: parts ++ [error], else: parts
      parts = if desc, do: parts ++ [desc], else: parts
      Enum.join(parts, ": ")
    end
  end

  defmodule RateLimitError do
    @moduledoc """
    Represents a 429 Too Many Requests response after retry exhaustion.

    ## Fields

    * `:retry_after` - The Retry-After header value in seconds (if provided)
    * `:message` - Human-readable error message
    """
    defexception [:retry_after, :message]

    @type t :: %__MODULE__{
            retry_after: integer() | nil,
            message: String.t()
          }

    @impl true
    def message(%__MODULE__{retry_after: retry_after, message: msg}) do
      base = msg || "Rate limited by Microsoft Graph API"
      if retry_after, do: "#{base} (retry after #{retry_after}s)", else: base
    end
  end
end
