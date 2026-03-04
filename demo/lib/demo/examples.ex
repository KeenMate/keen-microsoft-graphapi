defmodule Demo.Examples do
  @moduledoc """
  Runnable examples demonstrating the MicrosoftGraph library.

  Each function creates its own client, calls the API, and returns
  the result. Run them with:

      cd demo
      mix run -e "Demo.Examples.list_users() |> IO.inspect()"

  **Prerequisites:** Set the following environment variables:

  - `AZURE_TENANT_ID`
  - `AZURE_CLIENT_ID`
  - `AZURE_CLIENT_SECRET`
  """

  alias MicrosoftGraph.{Users, OData, Pagination}
  alias MicrosoftGraph.Schema

  @doc """
  Lists the first page of users from Microsoft Graph.

  Returns a raw map with `"value"` containing user maps.
  """
  def list_users do
    client = MicrosoftGraph.Client.new()
    Users.list(client: client)
  end

  @doc """
  Gets a single user by ID or UPN and casts the response to a schema struct.

  ## Example

      Demo.Examples.get_user("user@contoso.com")
      #=> {:ok, %MicrosoftGraph.Schema.User{display_name: "...", ...}}

  """
  def get_user(user_id) do
    client = MicrosoftGraph.Client.new()
    Users.get(user_id, client: client, as: Schema.User)
  end

  @doc """
  Lists users using a View struct for automatic `$select` injection.

  The `Demo.Views.UserSummary` view defines which fields to request.
  The library automatically adds the matching `$select` query parameter
  and casts each result into a `%Demo.Views.UserSummary{}` struct.
  """
  def list_users_with_view do
    client = MicrosoftGraph.Client.new()

    query =
      OData.new()
      |> OData.filter("accountEnabled eq true")
      |> OData.top(10)
      |> OData.orderby("displayName")

    Users.list(client: client, query: query, as: Demo.Views.UserSummary)
  end

  @doc """
  Demonstrates stream-based pagination to lazily fetch all users.

  Returns a list of all user maps across all pages.
  """
  def paginate_users do
    client = MicrosoftGraph.Client.new()

    query =
      OData.new()
      |> OData.select(["id", "displayName", "mail"])
      |> OData.top(100)

    with {:ok, first_page} <- Users.list(client: client, query: query) do
      all_users =
        Pagination.stream(first_page, client: client)
        |> Enum.to_list()

      {:ok, all_users}
    end
  end
end
