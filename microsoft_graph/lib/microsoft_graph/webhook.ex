defmodule MicrosoftGraph.Webhook do
  @moduledoc """
  Helpers for handling Microsoft Graph webhook notifications.

  When you create a subscription, Microsoft Graph first sends a **validation request**
  to confirm your endpoint. After that, it sends **notification requests** whenever
  the subscribed resource changes.

  ## Validation Flow

  Microsoft sends a POST with `?validationToken=<token>` as a query parameter.
  Your endpoint must respond with `200 OK` and the token as plain text.

  ## Notification Flow

  Microsoft sends a POST with a JSON body containing an array of notifications
  under the `"value"` key. Your endpoint must respond with `202 Accepted`
  within 3 seconds.

  ## Example (Plug/Phoenix)

      def webhook(conn, params) do
        case MicrosoftGraph.Webhook.classify(conn) do
          {:validate, token} ->
            conn
            |> put_resp_content_type("text/plain")
            |> send_resp(200, token)

          :notification ->
            notifications = MicrosoftGraph.Webhook.parse_notifications(conn.body_params)

            for n <- notifications do
              # Process asynchronously to respond within 3 seconds
              MyApp.NotificationWorker.enqueue(n)
            end

            send_resp(conn, 202, "")
        end
      end
  """

  @doc """
  Classifies an incoming webhook request.

  Returns `{:validate, token}` if this is a subscription validation request,
  or `:notification` if this is a change notification.

  ## Parameters

  * `conn_or_params` — A `Plug.Conn` struct or a params map with string keys

  ## Examples

      case Webhook.classify(conn) do
        {:validate, token} -> send_resp(conn, 200, token)
        :notification -> process_and_respond_202(conn)
      end
  """
  @spec classify(Plug.Conn.t() | map()) :: {:validate, String.t()} | :notification
  def classify(%Plug.Conn{} = conn) do
    conn = Plug.Conn.fetch_query_params(conn)
    classify_params(conn.query_params)
  end

  def classify(%{} = params) do
    classify_params(params)
  end

  defp classify_params(params) do
    case Map.get(params, "validationToken") do
      nil -> :notification
      token when is_binary(token) -> {:validate, token}
    end
  end

  @doc """
  Parses notifications from a webhook request body.

  Returns a list of notification maps, each containing:
  * `"subscriptionId"` — The subscription that triggered this notification
  * `"changeType"` — `"created"`, `"updated"`, or `"deleted"`
  * `"resource"` — The resource path that changed (e.g., `"users/user-id"`)
  * `"resourceData"` — Additional data about the resource (if included)
  * `"clientState"` — The client state string from the subscription (for validation)

  ## Parameters

  * `body` — The parsed JSON body (map with string keys)

  ## Examples

      notifications = Webhook.parse_notifications(conn.body_params)
      # => [%{"subscriptionId" => "...", "changeType" => "updated", "resource" => "users/abc", ...}]
  """
  @spec parse_notifications(map()) :: [map()]
  def parse_notifications(%{"value" => notifications}) when is_list(notifications) do
    notifications
  end

  def parse_notifications(_body), do: []

  @doc """
  Validates the `clientState` of a notification against an expected value.

  Returns `true` if the notification's `clientState` matches the expected value.
  This helps verify that notifications are genuinely from Microsoft Graph and not spoofed.

  ## Examples

      for notification <- Webhook.parse_notifications(body) do
        if Webhook.valid_client_state?(notification, "my-secret") do
          process(notification)
        else
          Logger.warning("Invalid clientState, ignoring notification")
        end
      end
  """
  @spec valid_client_state?(map(), String.t()) :: boolean()
  def valid_client_state?(%{"clientState" => state}, expected) when is_binary(expected) do
    Plug.Crypto.secure_compare(state, expected)
  end

  def valid_client_state?(_notification, _expected), do: false
end
