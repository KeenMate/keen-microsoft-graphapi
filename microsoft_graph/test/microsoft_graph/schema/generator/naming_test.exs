defmodule MicrosoftGraph.Schema.Generator.NamingTest do
  use ExUnit.Case, async: true

  alias MicrosoftGraph.Schema.Generator.Naming

  describe "camel_to_snake/1" do
    test "converts simple camelCase" do
      assert Naming.camel_to_snake("displayName") == "display_name"
      assert Naming.camel_to_snake("userPrincipalName") == "user_principal_name"
      assert Naming.camel_to_snake("jobTitle") == "job_title"
    end

    test "handles single word" do
      assert Naming.camel_to_snake("id") == "id"
      assert Naming.camel_to_snake("mail") == "mail"
    end

    test "handles PascalCase" do
      assert Naming.camel_to_snake("DisplayName") == "display_name"
      assert Naming.camel_to_snake("PasswordProfile") == "password_profile"
    end

    test "handles consecutive uppercase (acronyms)" do
      assert Naming.camel_to_snake("SMTPAddress") == "smtp_address"
      assert Naming.camel_to_snake("imAddresses") == "im_addresses"
      assert Naming.camel_to_snake("mySMTPAddress") == "my_smtp_address"
    end

    test "handles already snake_case" do
      assert Naming.camel_to_snake("already_snake") == "already_snake"
    end
  end

  describe "snake_to_camel/1" do
    test "converts snake_case to camelCase" do
      assert Naming.snake_to_camel("display_name") == "displayName"
      assert Naming.snake_to_camel("user_principal_name") == "userPrincipalName"
    end

    test "handles single word" do
      assert Naming.snake_to_camel("id") == "id"
      assert Naming.snake_to_camel("mail") == "mail"
    end
  end

  describe "entity_to_module_name/1" do
    test "capitalizes simple names" do
      assert Naming.entity_to_module_name("user") == "User"
      assert Naming.entity_to_module_name("group") == "Group"
    end

    test "converts camelCase to PascalCase" do
      assert Naming.entity_to_module_name("driveItem") == "DriveItem"
      assert Naming.entity_to_module_name("mailFolder") == "MailFolder"
      assert Naming.entity_to_module_name("passwordProfile") == "PasswordProfile"
    end

    test "handles already PascalCase" do
      assert Naming.entity_to_module_name("User") == "User"
    end
  end

  describe "extract_type_name/1" do
    test "extracts name from fully qualified type" do
      assert Naming.extract_type_name("microsoft.graph.user") == "user"
      assert Naming.extract_type_name("microsoft.graph.passwordProfile") == "passwordProfile"
    end

    test "handles simple name" do
      assert Naming.extract_type_name("user") == "user"
    end
  end

  describe "property_to_field/1" do
    test "converts camelCase to snake_case atom" do
      assert Naming.property_to_field("displayName") == :display_name
      assert Naming.property_to_field("id") == :id
      assert Naming.property_to_field("userPrincipalName") == :user_principal_name
    end
  end
end
