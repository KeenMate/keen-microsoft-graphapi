defmodule GraphApi.Schema.UserTest do
  use ExUnit.Case, async: true

  alias GraphApi.Schema.User
  alias GraphApi.Schema.PasswordProfile
  alias GraphApi.Schema.AssignedLicense

  @user_map %{
    "id" => "abc-123",
    "displayName" => "Alice Smith",
    "mail" => "alice@contoso.com",
    "userPrincipalName" => "alice@contoso.com",
    "jobTitle" => "Engineer",
    "accountEnabled" => true,
    "age" => 30,
    "height" => 1.75,
    "preferredLanguage" => "en-US",
    "proxyAddresses" => ["SMTP:alice@contoso.com"],
    "businessPhones" => ["+1-555-1234"],
    "companyName" => "Contoso",
    "employeeType" => "Employee",
    "passwordProfile" => %{
      "password" => "secret123",
      "forceChangePasswordNextSignIn" => true,
      "forceChangePasswordNextSignInWithMfa" => false
    },
    "assignedLicenses" => [
      %{"skuId" => "sku-1", "disabledPlans" => ["plan-a"]},
      %{"skuId" => "sku-2", "disabledPlans" => []}
    ]
  }

  describe "from_map/1" do
    test "converts basic string fields" do
      user = User.from_map(@user_map)
      assert user.id == "abc-123"
      assert user.display_name == "Alice Smith"
      assert user.mail == "alice@contoso.com"
      assert user.job_title == "Engineer"
    end

    test "converts boolean fields" do
      user = User.from_map(@user_map)
      assert user.account_enabled == true
    end

    test "converts numeric fields" do
      user = User.from_map(@user_map)
      assert user.age == 30
      assert user.height == 1.75
    end

    test "converts collection of strings" do
      user = User.from_map(@user_map)
      assert user.proxy_addresses == ["SMTP:alice@contoso.com"]
      assert user.business_phones == ["+1-555-1234"]
    end

    test "converts nested complex type (passwordProfile)" do
      user = User.from_map(@user_map)
      assert %PasswordProfile{} = user.password_profile
      assert user.password_profile.password == "secret123"
      assert user.password_profile.force_change_password_next_sign_in == true
    end

    test "converts collection of complex types (assignedLicenses)" do
      user = User.from_map(@user_map)
      assert [%AssignedLicense{} = first, %AssignedLicense{}] = user.assigned_licenses
      assert first.sku_id == "sku-1"
      assert first.disabled_plans == ["plan-a"]
    end

    test "handles nil/missing fields" do
      user = User.from_map(%{"id" => "123"})
      assert user.id == "123"
      assert user.display_name == nil
      assert user.password_profile == nil
      assert user.assigned_licenses == nil
    end
  end

  describe "to_map/1" do
    test "converts struct to camelCase map" do
      user = User.from_map(@user_map)
      map = User.to_map(user)

      assert map["displayName"] == "Alice Smith"
      assert map["mail"] == "alice@contoso.com"
      assert map["accountEnabled"] == true
    end

    test "omits nil fields" do
      user = %User{id: "123", display_name: "Test"}
      map = User.to_map(user)

      assert map["id"] == "123"
      assert map["displayName"] == "Test"
      refute Map.has_key?(map, "mail")
      refute Map.has_key?(map, "jobTitle")
    end

    test "converts nested complex types back to maps" do
      user = User.from_map(@user_map)
      map = User.to_map(user)

      assert map["passwordProfile"]["password"] == "secret123"
      assert [first | _] = map["assignedLicenses"]
      assert first["skuId"] == "sku-1"
    end
  end

  describe "__field_mapping__/0" do
    test "returns mapping from camelCase to snake_case atoms" do
      mapping = User.__field_mapping__()
      assert mapping["displayName"] == :display_name
      assert mapping["userPrincipalName"] == :user_principal_name
      assert mapping["id"] == :id
    end
  end

  describe "__field_names__/0" do
    test "returns list of camelCase field names" do
      names = User.__field_names__()
      assert "displayName" in names
      assert "mail" in names
      assert "id" in names
    end
  end

  describe "round-trip" do
    test "from_map then to_map preserves data" do
      user = User.from_map(@user_map)
      map = User.to_map(user)

      # Verify key fields survive the round trip
      assert map["id"] == @user_map["id"]
      assert map["displayName"] == @user_map["displayName"]
      assert map["accountEnabled"] == @user_map["accountEnabled"]
      assert map["age"] == @user_map["age"]
      assert map["passwordProfile"]["password"] == @user_map["passwordProfile"]["password"]
    end
  end
end
