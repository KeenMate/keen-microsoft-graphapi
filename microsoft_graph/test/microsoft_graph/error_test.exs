defmodule MicrosoftGraph.ErrorTest do
  use ExUnit.Case, async: true

  alias MicrosoftGraph.Error.{ApiError, AuthError, RateLimitError}

  describe "ApiError" do
    test "formats message with status, code, and message" do
      error = %ApiError{status: 404, code: "Request_ResourceNotFound", message: "Not found"}

      assert Exception.message(error) ==
               "Graph API error (404): code=Request_ResourceNotFound: Not found"
    end

    test "formats message without code" do
      error = %ApiError{status: 500, code: nil, message: "Internal error"}
      assert Exception.message(error) == "Graph API error (500): Internal error"
    end

    test "formats message without message" do
      error = %ApiError{status: 403, code: "Authorization_RequestDenied", message: nil}
      assert Exception.message(error) == "Graph API error (403): code=Authorization_RequestDenied"
    end

    test "is an exception" do
      assert_raise ApiError, fn ->
        raise %ApiError{status: 404, code: "NotFound", message: "Not found"}
      end
    end
  end

  describe "AuthError" do
    test "formats message with status, error, and description" do
      error = %AuthError{
        status: 401,
        error: "invalid_client",
        error_description: "Bad secret"
      }

      assert Exception.message(error) == "Auth error (401): invalid_client: Bad secret"
    end

    test "formats message without description" do
      error = %AuthError{status: 401, error: "invalid_client", error_description: nil}
      assert Exception.message(error) == "Auth error (401): invalid_client"
    end

    test "is an exception" do
      assert_raise AuthError, fn ->
        raise %AuthError{status: 401, error: "invalid_client", error_description: "Bad"}
      end
    end
  end

  describe "RateLimitError" do
    test "formats message with retry_after" do
      error = %RateLimitError{retry_after: 10, message: "Rate limited"}
      assert Exception.message(error) == "Rate limited (retry after 10s)"
    end

    test "formats message without retry_after" do
      error = %RateLimitError{retry_after: nil, message: "Rate limited"}
      assert Exception.message(error) == "Rate limited"
    end

    test "uses default message when message is nil" do
      error = %RateLimitError{retry_after: 5, message: nil}
      assert Exception.message(error) == "Rate limited by Microsoft Graph API (retry after 5s)"
    end

    test "is an exception" do
      assert_raise RateLimitError, fn ->
        raise %RateLimitError{retry_after: 10, message: "Too many requests"}
      end
    end
  end
end
