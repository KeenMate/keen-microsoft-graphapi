defmodule Mix.Tasks.Graph.Cleanup do
  @shortdoc "Remove residual test users and groups from Azure AD"

  @moduledoc """
  Cleans up users and groups left behind by failed integration test runs.

  Looks for objects whose `displayName` starts with "Integration Test User"
  or "Integration Test Group" and deletes them.

  ## Usage

      # Load credentials from .env.test and clean up
      mix graph.cleanup

      # Dry-run — list what would be deleted without deleting
      mix graph.cleanup --dry-run

  ## Credentials

  Reads `AZURE_TENANT_ID`, `AZURE_CLIENT_ID`, and `AZURE_CLIENT_SECRET`
  from the environment or from `.env.test` in the project root.
  """
  use Mix.Task

  alias MicrosoftGraph.{Config, Client, Groups, OData, Users}

  @user_prefix "Integration Test User"
  @group_prefix "Integration Test Group"

  @impl Mix.Task
  def run(args) do
    dry_run? = "--dry-run" in args

    Mix.Task.run("app.start")
    load_env_file()

    client = build_client()

    if dry_run? do
      Mix.shell().info("DRY RUN — nothing will be deleted.\n")
    end

    deleted_groups = cleanup_groups(client, dry_run?)
    deleted_users = cleanup_users(client, dry_run?)

    Mix.shell().info("")

    if dry_run? do
      Mix.shell().info(
        "Would delete #{deleted_users} user(s) and #{deleted_groups} group(s). " <>
          "Run without --dry-run to execute."
      )
    else
      Mix.shell().info("Cleaned up #{deleted_users} user(s) and #{deleted_groups} group(s).")
    end
  end

  defp cleanup_users(client, dry_run?) do
    Mix.shell().info("Looking for test users (displayName starts with #{inspect(@user_prefix)})...")

    query =
      OData.new()
      |> OData.filter("startsWith(displayName, '#{@user_prefix}')")
      |> OData.select(["id", "displayName", "userPrincipalName"])
      |> OData.top(100)

    case Users.list(client: client, query: query) do
      {:ok, %{"value" => users}} when users != [] ->
        Mix.shell().info("  Found #{length(users)} test user(s):")

        Enum.each(users, fn user ->
          label = "#{user["displayName"]} (#{user["userPrincipalName"] || user["id"]})"

          if dry_run? do
            Mix.shell().info("    [skip] #{label}")
          else
            case Users.delete(user["id"], client: client) do
              :ok ->
                Mix.shell().info("    [deleted] #{label}")

              {:error, reason} ->
                Mix.shell().error("    [error]   #{label} — #{inspect(reason)}")
            end
          end
        end)

        length(users)

      {:ok, %{"value" => []}} ->
        Mix.shell().info("  No test users found.")
        0

      {:error, reason} ->
        Mix.shell().error("  Failed to list users: #{inspect(reason)}")
        0
    end
  end

  defp cleanup_groups(client, dry_run?) do
    Mix.shell().info(
      "Looking for test groups (displayName starts with #{inspect(@group_prefix)})..."
    )

    query =
      OData.new()
      |> OData.filter("startsWith(displayName, '#{@group_prefix}')")
      |> OData.select(["id", "displayName"])
      |> OData.top(100)

    case Groups.list(client: client, query: query) do
      {:ok, %{"value" => groups}} when groups != [] ->
        Mix.shell().info("  Found #{length(groups)} test group(s):")

        Enum.each(groups, fn group ->
          label = "#{group["displayName"]} (#{group["id"]})"

          if dry_run? do
            Mix.shell().info("    [skip] #{label}")
          else
            case Groups.delete(group["id"], client: client) do
              :ok ->
                Mix.shell().info("    [deleted] #{label}")

              {:error, reason} ->
                Mix.shell().error("    [error]   #{label} — #{inspect(reason)}")
            end
          end
        end)

        length(groups)

      {:ok, %{"value" => []}} ->
        Mix.shell().info("  No test groups found.")
        0

      {:error, reason} ->
        Mix.shell().error("  Failed to list groups: #{inspect(reason)}")
        0
    end
  end

  defp build_client do
    config =
      Config.new!(
        tenant_id: System.fetch_env!("AZURE_TENANT_ID"),
        client_id: System.fetch_env!("AZURE_CLIENT_ID"),
        client_secret: System.fetch_env!("AZURE_CLIENT_SECRET")
      )

    Client.new(config: config)
  end

  defp load_env_file do
    path = Path.join(File.cwd!(), ".env.test")

    if File.exists?(path) do
      path
      |> File.read!()
      |> String.split("\n")
      |> Enum.each(fn line ->
        line = String.trim(line)

        with false <- line == "",
             false <- String.starts_with?(line, "#"),
             [key, value] <- String.split(line, "=", parts: 2) do
          key = String.trim(key)
          value = String.trim(value)
          if System.get_env(key) == nil, do: System.put_env(key, value)
        end
      end)
    end
  end
end
