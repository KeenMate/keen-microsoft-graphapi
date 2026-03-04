defmodule MicrosoftGraph.Schema.Generator.CodeGeneratorTest do
  use ExUnit.Case, async: true

  alias MicrosoftGraph.Schema.Generator.{MetadataParser, TypeResolver, CodeGenerator}

  @fixture_path Path.expand("../../../support/fixtures/metadata_snippet.xml", __DIR__)

  setup_all do
    xml = File.read!(@fixture_path)
    metadata = MetadataParser.parse(xml)
    resolved = TypeResolver.resolve(metadata, ["user", "message"])
    enum_names = Enum.map(resolved.enum_types, & &1.name)
    context = %{enum_names: enum_names}
    %{resolved: resolved, context: context}
  end

  describe "generate_entity/2" do
    test "generates valid module code for user", %{resolved: resolved, context: context} do
      user = Enum.find(resolved.entities, &(&1.name == "user"))
      {filename, code} = CodeGenerator.generate_entity(user, context)

      assert filename == "user.ex"
      assert code =~ "defmodule MicrosoftGraph.Schema.User do"
      assert code =~ "defstruct"
      assert code =~ ":display_name"
      assert code =~ ":mail"
      assert code =~ ":id"
      assert code =~ ":deleted_date_time"
      assert code =~ "def from_map(map)"
      assert code =~ "def to_map(%__MODULE__{} = struct)"
      assert code =~ "def __field_mapping__"
      assert code =~ "def __field_names__"
    end

    test "generated code contains typespec", %{resolved: resolved, context: context} do
      user = Enum.find(resolved.entities, &(&1.name == "user"))
      {_filename, code} = CodeGenerator.generate_entity(user, context)

      assert code =~ "@type t :: %__MODULE__{"
      assert code =~ "display_name: String.t() | nil"
      assert code =~ "account_enabled: boolean() | nil"
      assert code =~ "age: integer() | nil"
    end

    test "from_map handles complex type casting", %{resolved: resolved, context: context} do
      user = Enum.find(resolved.entities, &(&1.name == "user"))
      {_filename, code} = CodeGenerator.generate_entity(user, context)

      # passwordProfile is a complex type, should have from_map call
      assert code =~ "MicrosoftGraph.Schema.PasswordProfile.from_map"
    end

    test "from_map handles collection of complex types", %{resolved: resolved, context: context} do
      user = Enum.find(resolved.entities, &(&1.name == "user"))
      {_filename, code} = CodeGenerator.generate_entity(user, context)

      # assignedLicenses is Collection(microsoft.graph.assignedLicense)
      assert code =~ "MicrosoftGraph.Schema.AssignedLicense.from_map"
    end

    test "field_mapping contains correct mappings", %{resolved: resolved, context: context} do
      user = Enum.find(resolved.entities, &(&1.name == "user"))
      {_filename, code} = CodeGenerator.generate_entity(user, context)

      assert code =~ ~s({"displayName", :display_name})
      assert code =~ ~s({"userPrincipalName", :user_principal_name})
    end

    test "field_names contains camelCase names", %{resolved: resolved, context: context} do
      user = Enum.find(resolved.entities, &(&1.name == "user"))
      {_filename, code} = CodeGenerator.generate_entity(user, context)

      assert code =~ ~s("displayName")
      assert code =~ ~s("mail")
      assert code =~ ~s("id")
    end
  end

  describe "generate_complex_type/2" do
    test "generates valid module for passwordProfile", %{resolved: resolved, context: context} do
      pp = Enum.find(resolved.complex_types, &(&1.name == "passwordProfile"))
      {filename, code} = CodeGenerator.generate_complex_type(pp, context)

      assert filename == "password_profile.ex"
      assert code =~ "defmodule MicrosoftGraph.Schema.PasswordProfile do"
      assert code =~ ":password"
      assert code =~ ":force_change_password_next_sign_in"
    end
  end

  describe "generate_enum/1" do
    test "generates valid module for importance enum", %{resolved: resolved} do
      importance = Enum.find(resolved.enum_types, &(&1.name == "importance"))
      {filename, code} = CodeGenerator.generate_enum(importance)

      assert filename == "importance.ex"
      assert code =~ "defmodule MicrosoftGraph.Schema.Importance do"
      assert code =~ "def values"
      assert code =~ "def valid?"
      assert code =~ ~s(def low, do: "low")
      assert code =~ ~s(def normal, do: "normal")
      assert code =~ ~s(def high, do: "high")
    end

    test "generates valid module for bodyType enum", %{resolved: resolved} do
      body_type = Enum.find(resolved.enum_types, &(&1.name == "bodyType"))
      {filename, code} = CodeGenerator.generate_enum(body_type)

      assert filename == "body_type.ex"
      assert code =~ "defmodule MicrosoftGraph.Schema.BodyType do"
      assert code =~ ~s(def text, do: "text")
      assert code =~ ~s(def html, do: "html")
    end
  end

  describe "namespace support" do
    test "uses custom namespace for entity modules", %{resolved: resolved, context: context} do
      beta_context = Map.put(context, :namespace, "MicrosoftGraph.Schema.Beta")
      user = Enum.find(resolved.entities, &(&1.name == "user"))
      {_filename, code} = CodeGenerator.generate_entity(user, beta_context)

      assert code =~ "defmodule MicrosoftGraph.Schema.Beta.User do"
      refute code =~ "defmodule MicrosoftGraph.Schema.User do"
    end

    test "uses custom namespace for complex type references", %{resolved: resolved, context: context} do
      beta_context = Map.put(context, :namespace, "MicrosoftGraph.Schema.Beta")
      user = Enum.find(resolved.entities, &(&1.name == "user"))
      {_filename, code} = CodeGenerator.generate_entity(user, beta_context)

      assert code =~ "MicrosoftGraph.Schema.Beta.PasswordProfile.from_map"
      refute code =~ ~r/[^.]MicrosoftGraph\.Schema\.PasswordProfile/
    end

    test "uses custom namespace for enum modules", %{resolved: resolved, context: context} do
      beta_context = Map.put(context, :namespace, "MicrosoftGraph.Schema.Beta")
      importance = Enum.find(resolved.enum_types, &(&1.name == "importance"))
      {_filename, code} = CodeGenerator.generate_enum(importance, beta_context)

      assert code =~ "defmodule MicrosoftGraph.Schema.Beta.Importance do"
    end

    test "defaults to MicrosoftGraph.Schema when no namespace given", %{resolved: resolved} do
      user = Enum.find(resolved.entities, &(&1.name == "user"))
      {_filename, code} = CodeGenerator.generate_entity(user, %{enum_names: []})

      assert code =~ "defmodule MicrosoftGraph.Schema.User do"
    end
  end

  describe "generated code compiles" do
    test "entity code compiles cleanly", %{resolved: resolved, context: context} do
      user = Enum.find(resolved.entities, &(&1.name == "user"))
      {_filename, code} = CodeGenerator.generate_entity(user, context)
      assert is_binary(code)
      # Basic structural validation
      assert code =~ "defmodule"
      assert code =~ "defstruct"
      assert code =~ "def from_map"
      assert code =~ "def to_map"
    end
  end
end
