defmodule MicrosoftGraph.Integration.DelegatedTest do
  @moduledoc """
  Integration tests using a delegated (user) access token.

  Requires AZURE_USER_ACCESS_TOKEN in `.env.test`.
  Run with: mix test --include integration_delegated
  """
  use ExUnit.Case

  @moduletag :integration_delegated

  setup_all do
    token = System.get_env("AZURE_USER_ACCESS_TOKEN")

    if is_nil(token) or token == "" do
      raise """
      Missing AZURE_USER_ACCESS_TOKEN for delegated integration tests.
      Get one from Graph Explorer or: az account get-access-token --resource https://graph.microsoft.com
      """
    end

    client = MicrosoftGraph.Client.new()
    %{client: client, token: token}
  end

  describe "delegated /me endpoint" do
    test "get my profile", %{client: client, token: token} do
      assert {:ok, me} = MicrosoftGraph.Users.get("me", client: client, access_token: token)
      assert is_binary(me["displayName"])
      IO.puts("  Signed in as: #{me["displayName"]} (#{me["mail"]})")
    end

    test "list my mail folders", %{client: client, token: token} do
      assert {:ok, %{"value" => folders}} =
               MicrosoftGraph.Mail.list_mail_folders("me", client: client, access_token: token)

      assert is_list(folders)
      IO.puts("  Found #{length(folders)} mail folders")
    end

    test "list my events", %{client: client, token: token} do
      assert {:ok, %{"value" => events}} =
               MicrosoftGraph.Calendar.list_events("me", client: client, access_token: token)

      assert is_list(events)
      IO.puts("  Found #{length(events)} events")
    end

    test "get my drive", %{client: client, token: token} do
      assert {:ok, drive} =
               MicrosoftGraph.Files.get_drive("me", client: client, access_token: token)

      assert is_binary(drive["id"])
      IO.puts("  Drive: #{drive["name"]} (#{drive["driveType"]})")
    end
  end
end
