defmodule GraphApi.Schema.Generator.MetadataParserTest do
  use ExUnit.Case, async: true

  alias GraphApi.Schema.Generator.MetadataParser

  @fixture_path Path.expand("../../../support/fixtures/metadata_snippet.xml", __DIR__)

  setup_all do
    xml = File.read!(@fixture_path)
    metadata = MetadataParser.parse(xml)
    %{metadata: metadata}
  end

  describe "parse/1 entity types" do
    test "parses all entity types", %{metadata: metadata} do
      entity_names = Map.keys(metadata.entity_types)
      assert "user" in entity_names
      assert "group" in entity_names
      assert "message" in entity_names
      assert "event" in entity_names
      assert "driveItem" in entity_names
      assert "entity" in entity_names
      assert "directoryObject" in entity_names
    end

    test "parses entity with base type", %{metadata: metadata} do
      user = metadata.entity_types["user"]
      assert user.name == "user"
      assert user.base_type == "microsoft.graph.directoryObject"
    end

    test "parses abstract base entity without base type", %{metadata: metadata} do
      entity = metadata.entity_types["entity"]
      assert entity.name == "entity"
      assert entity.base_type == nil
    end

    test "parses entity properties", %{metadata: metadata} do
      user = metadata.entity_types["user"]
      prop_names = Enum.map(user.properties, & &1.name)
      assert "displayName" in prop_names
      assert "mail" in prop_names
      assert "accountEnabled" in prop_names
      assert "passwordProfile" in prop_names
    end

    test "parses property types correctly", %{metadata: metadata} do
      user = metadata.entity_types["user"]
      props = Map.new(user.properties, fn p -> {p.name, p.type} end)

      assert props["displayName"] == "Edm.String"
      assert props["accountEnabled"] == "Edm.Boolean"
      assert props["age"] == "Edm.Int32"
      assert props["height"] == "Edm.Double"
      assert props["passwordProfile"] == "microsoft.graph.passwordProfile"
      assert props["assignedLicenses"] == "Collection(microsoft.graph.assignedLicense)"
      assert props["proxyAddresses"] == "Collection(Edm.String)"
    end

    test "parses navigation properties", %{metadata: metadata} do
      user = metadata.entity_types["user"]
      nav_names = Enum.map(user.nav_properties, & &1.name)
      assert "manager" in nav_names
      assert "directReports" in nav_names
    end
  end

  describe "parse/1 complex types" do
    test "parses all complex types", %{metadata: metadata} do
      complex_names = Map.keys(metadata.complex_types)
      assert "passwordProfile" in complex_names
      assert "assignedLicense" in complex_names
      assert "emailAddress" in complex_names
      assert "itemBody" in complex_names
      assert "recipient" in complex_names
    end

    test "parses complex type properties", %{metadata: metadata} do
      pp = metadata.complex_types["passwordProfile"]
      prop_names = Enum.map(pp.properties, & &1.name)
      assert "password" in prop_names
      assert "forceChangePasswordNextSignIn" in prop_names
    end

    test "parses nested complex type references", %{metadata: metadata} do
      recipient = metadata.complex_types["recipient"]
      email_prop = Enum.find(recipient.properties, &(&1.name == "emailAddress"))
      assert email_prop.type == "microsoft.graph.emailAddress"
    end
  end

  describe "parse/1 enum types" do
    test "parses all enum types", %{metadata: metadata} do
      enum_names = Map.keys(metadata.enum_types)
      assert "importance" in enum_names
      assert "sensitivity" in enum_names
      assert "bodyType" in enum_names
      assert "calendarColor" in enum_names
    end

    test "parses enum members", %{metadata: metadata} do
      importance = metadata.enum_types["importance"]
      member_names = Enum.map(importance.members, & &1.name)
      assert member_names == ["low", "normal", "high"]
    end

    test "parses enum member values", %{metadata: metadata} do
      importance = metadata.enum_types["importance"]
      high = Enum.find(importance.members, &(&1.name == "high"))
      assert high.value == "2"
    end
  end
end
