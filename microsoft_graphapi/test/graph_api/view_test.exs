defmodule GraphApi.ViewTest do
  use ExUnit.Case, async: true

  # Define a test view module
  defmodule UserSummary do
    use GraphApi.View,
      schema: GraphApi.Schema.User,
      fields: [:id, :display_name, :mail, :job_title]
  end

  # Define another view with nested complex type field
  defmodule UserWithPassword do
    use GraphApi.View,
      schema: GraphApi.Schema.User,
      fields: [:id, :display_name, :password_profile]
  end

  @user_map %{
    "id" => "abc-123",
    "displayName" => "Alice Smith",
    "mail" => "alice@contoso.com",
    "userPrincipalName" => "alice@contoso.com",
    "jobTitle" => "Engineer",
    "accountEnabled" => true,
    "passwordProfile" => %{
      "password" => "secret",
      "forceChangePasswordNextSignIn" => true,
      "forceChangePasswordNextSignInWithMfa" => false
    }
  }

  describe "defstruct" do
    test "view struct has only listed fields" do
      summary = %UserSummary{}
      keys = Map.keys(summary) -- [:__struct__]
      assert Enum.sort(keys) == Enum.sort([:id, :display_name, :mail, :job_title])
    end
  end

  describe "__select__/0" do
    test "returns camelCase field names for OData $select" do
      select = UserSummary.__select__()
      assert Enum.sort(select) == Enum.sort(["id", "displayName", "mail", "jobTitle"])
    end
  end

  describe "__schema__/0" do
    test "returns the parent schema module" do
      assert UserSummary.__schema__() == GraphApi.Schema.User
    end
  end

  describe "from_map/1" do
    test "creates view struct from API response map" do
      summary = UserSummary.from_map(@user_map)
      assert %UserSummary{} = summary
      assert summary.id == "abc-123"
      assert summary.display_name == "Alice Smith"
      assert summary.mail == "alice@contoso.com"
      assert summary.job_title == "Engineer"
    end

    test "excludes fields not in the view" do
      summary = UserSummary.from_map(@user_map)
      refute Map.has_key?(Map.from_struct(summary), :account_enabled)
      refute Map.has_key?(Map.from_struct(summary), :user_principal_name)
    end

    test "handles nested complex types in view" do
      view = UserWithPassword.from_map(@user_map)
      assert %GraphApi.Schema.PasswordProfile{} = view.password_profile
      assert view.password_profile.password == "secret"
    end
  end

  describe "to_map/1" do
    test "converts view back to camelCase map" do
      summary = %UserSummary{
        id: "abc-123",
        display_name: "Alice Smith",
        mail: "alice@contoso.com",
        job_title: "Engineer"
      }

      map = UserSummary.to_map(summary)
      assert map["id"] == "abc-123"
      assert map["displayName"] == "Alice Smith"
      assert map["mail"] == "alice@contoso.com"
      assert map["jobTitle"] == "Engineer"
    end

    test "omits nil fields from view" do
      summary = %UserSummary{id: "123", display_name: "Test"}
      map = UserSummary.to_map(summary)

      assert map["id"] == "123"
      assert map["displayName"] == "Test"
      refute Map.has_key?(map, "mail")
      refute Map.has_key?(map, "jobTitle")
    end
  end

  describe "compile-time validation" do
    test "raises CompileError for invalid field" do
      assert_raise CompileError, fn ->
        Code.compile_string("""
        defmodule GraphApi.ViewTest.BadView do
          use GraphApi.View,
            schema: GraphApi.Schema.User,
            fields: [:id, :nonexistent_field]
        end
        """)
      end
    end
  end
end
