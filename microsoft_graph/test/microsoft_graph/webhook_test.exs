defmodule MicrosoftGraph.WebhookTest do
  use ExUnit.Case, async: true

  alias MicrosoftGraph.Webhook

  describe "classify/1" do
    test "returns {:validate, token} for validation requests" do
      conn = Plug.Test.conn(:post, "/webhook?validationToken=abc123")
      assert {:validate, "abc123"} = Webhook.classify(conn)
    end

    test "returns :notification for notification requests" do
      conn = Plug.Test.conn(:post, "/webhook")
      assert :notification = Webhook.classify(conn)
    end

    test "works with params map directly" do
      assert {:validate, "token-xyz"} = Webhook.classify(%{"validationToken" => "token-xyz"})
      assert :notification = Webhook.classify(%{})
    end

    test "handles URL-encoded validation tokens" do
      conn = Plug.Test.conn(:post, "/webhook?validationToken=hello%20world")
      assert {:validate, "hello world"} = Webhook.classify(conn)
    end
  end

  describe "parse_notifications/1" do
    test "extracts notifications from body" do
      body = %{
        "value" => [
          %{
            "subscriptionId" => "sub-1",
            "changeType" => "updated",
            "resource" => "users/user-1",
            "clientState" => "my-secret",
            "resourceData" => %{
              "@odata.type" => "#Microsoft.Graph.User",
              "id" => "user-1"
            }
          },
          %{
            "subscriptionId" => "sub-1",
            "changeType" => "created",
            "resource" => "users/user-2",
            "clientState" => "my-secret"
          }
        ]
      }

      notifications = Webhook.parse_notifications(body)
      assert length(notifications) == 2
      assert hd(notifications)["changeType"] == "updated"
      assert hd(notifications)["resource"] == "users/user-1"
    end

    test "returns empty list for missing value key" do
      assert [] = Webhook.parse_notifications(%{})
    end

    test "returns empty list for non-list value" do
      assert [] = Webhook.parse_notifications(%{"value" => "not a list"})
    end
  end

  describe "valid_client_state?/2" do
    test "returns true when clientState matches" do
      notification = %{"clientState" => "my-secret", "changeType" => "updated"}
      assert Webhook.valid_client_state?(notification, "my-secret")
    end

    test "returns false when clientState does not match" do
      notification = %{"clientState" => "wrong-secret", "changeType" => "updated"}
      refute Webhook.valid_client_state?(notification, "my-secret")
    end

    test "returns false when clientState is missing" do
      notification = %{"changeType" => "updated"}
      refute Webhook.valid_client_state?(notification, "my-secret")
    end
  end
end
