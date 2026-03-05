defmodule GraphApi.ResourceAsTest do
  use ExUnit.Case, async: true

  alias GraphApi.Resource
  alias GraphApi.OData
  alias GraphApi.Schema.User

  # Define a test view
  defmodule UserSummary do
    use GraphApi.View,
      schema: GraphApi.Schema.User,
      fields: [:id, :display_name, :mail]
  end

  @user_response %{
    "id" => "user-1",
    "displayName" => "Alice Smith",
    "mail" => "alice@contoso.com",
    "userPrincipalName" => "alice@contoso.com",
    "jobTitle" => "Engineer",
    "accountEnabled" => true
  }

  @list_response %{
    "value" => [
      %{
        "id" => "user-1",
        "displayName" => "Alice Smith",
        "mail" => "alice@contoso.com"
      },
      %{
        "id" => "user-2",
        "displayName" => "Bob Jones",
        "mail" => "bob@contoso.com"
      }
    ]
  }

  setup do
    stub_name = :"resource_as_test_#{System.unique_integer([:positive])}"

    Req.Test.stub(stub_name, fn conn ->
      case {conn.method, conn.request_path} do
        {"GET", "/users/user-1"} ->
          Req.Test.json(conn, @user_response)

        {"GET", "/users"} ->
          Req.Test.json(conn, @list_response)

        {"POST", "/users"} ->
          conn
          |> Plug.Conn.put_status(201)
          |> Req.Test.json(@user_response)

        {"PATCH", "/users/user-1"} ->
          Req.Test.json(conn, @user_response)

        {"DELETE", "/users/user-1"} ->
          Plug.Conn.send_resp(conn, 204, "")

        _ ->
          Plug.Conn.send_resp(conn, 404, "")
      end
    end)

    client = Req.new(plug: {Req.Test, stub_name})
    %{client: client}
  end

  describe "GET with as: schema" do
    test "casts single item to schema struct", %{client: client} do
      assert {:ok, %User{} = user} = Resource.get("/users/user-1", client: client, as: User)
      assert user.display_name == "Alice Smith"
      assert user.mail == "alice@contoso.com"
      assert user.id == "user-1"
    end

    test "casts list items to schema structs", %{client: client} do
      assert {:ok, %{"value" => [%User{} = first, %User{} = second]}} =
               Resource.get("/users", client: client, as: User)

      assert first.display_name == "Alice Smith"
      assert second.display_name == "Bob Jones"
    end
  end

  describe "GET with as: view" do
    test "casts single item to view struct", %{client: client} do
      assert {:ok, %UserSummary{} = user} =
               Resource.get("/users/user-1", client: client, as: UserSummary)

      assert user.display_name == "Alice Smith"
      assert user.mail == "alice@contoso.com"
      assert user.id == "user-1"
    end

    test "casts list items to view structs", %{client: client} do
      assert {:ok, %{"value" => [%UserSummary{}, %UserSummary{}]}} =
               Resource.get("/users", client: client, as: UserSummary)
    end
  end

  describe "POST with as:" do
    test "casts response to schema struct", %{client: client} do
      body = %{"displayName" => "New User"}

      assert {:ok, %User{} = user} =
               Resource.post("/users", body, client: client, as: User)

      assert user.display_name == "Alice Smith"
    end
  end

  describe "PATCH with as:" do
    test "casts response to schema struct", %{client: client} do
      body = %{"displayName" => "Updated"}

      assert {:ok, %User{} = user} =
               Resource.patch("/users/user-1", body, client: client, as: User)

      assert user.display_name == "Alice Smith"
    end
  end

  describe "DELETE with as:" do
    test "passes through :ok regardless of as:", %{client: client} do
      assert :ok = Resource.delete("/users/user-1", client: client, as: User)
    end
  end

  describe "without as:" do
    test "returns raw maps as before", %{client: client} do
      assert {:ok, %{"displayName" => "Alice Smith"}} =
               Resource.get("/users/user-1", client: client)
    end
  end

  describe "maybe_inject_select/2" do
    test "injects $select for view modules with __select__" do
      opts = []
      result = Resource.maybe_inject_select(opts, UserSummary)
      query = Keyword.get(result, :query)
      assert %OData{select: select} = query
      assert "id" in select
      assert "displayName" in select
      assert "mail" in select
    end

    test "does not inject when query already has $select" do
      opts = [query: OData.new() |> OData.select(["id"])]
      result = Resource.maybe_inject_select(opts, UserSummary)
      query = Keyword.get(result, :query)
      assert %OData{select: ["id"]} = query
    end

    test "does not inject when map query has $select" do
      opts = [query: %{"$select" => "id"}]
      result = Resource.maybe_inject_select(opts, UserSummary)
      query = Keyword.get(result, :query)
      assert query == %{"$select" => "id"}
    end

    test "does not inject for schema modules without __select__" do
      # User schema module doesn't have __select__
      opts = []
      result = Resource.maybe_inject_select(opts, User)
      refute Keyword.has_key?(result, :query)
    end

    test "returns opts unchanged for nil module" do
      opts = [query: OData.new()]
      assert Resource.maybe_inject_select(opts, nil) == opts
    end
  end

  describe "maybe_cast/2" do
    test "casts single map body" do
      body = %{"id" => "1", "displayName" => "Test"}
      assert {:ok, %User{id: "1"}} = Resource.maybe_cast({:ok, body}, User)
    end

    test "casts list of items in value key" do
      body = %{"value" => [%{"id" => "1"}, %{"id" => "2"}]}
      assert {:ok, %{"value" => [%User{id: "1"}, %User{id: "2"}]}} = Resource.maybe_cast({:ok, body}, User)
    end

    test "passes through :ok" do
      assert :ok = Resource.maybe_cast(:ok, User)
    end

    test "passes through errors" do
      assert {:error, :some_error} = Resource.maybe_cast({:error, :some_error}, User)
    end

    test "returns result unchanged for nil module" do
      body = %{"id" => "1"}
      assert {:ok, ^body} = Resource.maybe_cast({:ok, body}, nil)
    end
  end
end
