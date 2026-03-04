defmodule MicrosoftGraph.Schema.Beta.UserTest do
  use ExUnit.Case, async: true

  alias MicrosoftGraph.Schema.Beta.User
  alias MicrosoftGraph.Schema.Beta.PasswordProfile

  @user_map %{
    "id" => "abc-123",
    "displayName" => "Alice Smith",
    "mail" => "alice@contoso.com",
    "userPrincipalName" => "alice@contoso.com",
    "jobTitle" => "Engineer",
    "accountEnabled" => true,
    "passwordProfile" => %{
      "password" => "secret123",
      "forceChangePasswordNextSignIn" => true,
      "forceChangePasswordNextSignInWithMfa" => false
    }
  }

  describe "from_map/1" do
    test "creates a Beta.User struct" do
      user = User.from_map(@user_map)
      assert %User{} = user
      assert user.id == "abc-123"
      assert user.display_name == "Alice Smith"
    end

    test "casts nested complex types within Beta namespace" do
      user = User.from_map(@user_map)
      assert %PasswordProfile{} = user.password_profile
      assert user.password_profile.password == "secret123"
    end
  end

  describe "to_map/1" do
    test "converts Beta.User struct to camelCase map" do
      user = User.from_map(@user_map)
      map = User.to_map(user)

      assert map["displayName"] == "Alice Smith"
      assert map["passwordProfile"]["password"] == "secret123"
    end
  end

  describe "__field_mapping__/0" do
    test "returns field mapping" do
      mapping = User.__field_mapping__()
      assert mapping["displayName"] == :display_name
    end
  end

  describe "__field_names__/0" do
    test "returns camelCase field names" do
      assert "displayName" in User.__field_names__()
    end
  end

  describe "view works with beta schema" do
    defmodule BetaUserSummary do
      use MicrosoftGraph.View,
        schema: MicrosoftGraph.Schema.Beta.User,
        fields: [:id, :display_name, :mail]
    end

    test "view casts from beta schema" do
      summary = BetaUserSummary.from_map(@user_map)
      assert %BetaUserSummary{} = summary
      assert summary.display_name == "Alice Smith"
    end

    test "view __select__ works" do
      select = BetaUserSummary.__select__()
      assert Enum.sort(select) == Enum.sort(["id", "displayName", "mail"])
    end

    test "view __schema__ returns beta module" do
      assert BetaUserSummary.__schema__() == MicrosoftGraph.Schema.Beta.User
    end
  end
end
