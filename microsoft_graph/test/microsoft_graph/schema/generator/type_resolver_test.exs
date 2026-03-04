defmodule MicrosoftGraph.Schema.Generator.TypeResolverTest do
  use ExUnit.Case, async: true

  alias MicrosoftGraph.Schema.Generator.{MetadataParser, TypeResolver}

  @fixture_path Path.expand("../../../support/fixtures/metadata_snippet.xml", __DIR__)

  setup_all do
    xml = File.read!(@fixture_path)
    metadata = MetadataParser.parse(xml)
    %{metadata: metadata}
  end

  describe "resolve_entity/2" do
    test "flattens user with full inheritance chain", %{metadata: metadata} do
      user = TypeResolver.resolve_entity("user", metadata)
      prop_names = Enum.map(user.properties, & &1.name)

      # From entity (root)
      assert "id" in prop_names
      # From directoryObject
      assert "deletedDateTime" in prop_names
      # From user itself
      assert "displayName" in prop_names
      assert "mail" in prop_names
      assert "passwordProfile" in prop_names
    end

    test "properties are ordered from root to leaf", %{metadata: metadata} do
      user = TypeResolver.resolve_entity("user", metadata)
      prop_names = Enum.map(user.properties, & &1.name)

      id_index = Enum.find_index(prop_names, &(&1 == "id"))
      deleted_index = Enum.find_index(prop_names, &(&1 == "deletedDateTime"))
      display_index = Enum.find_index(prop_names, &(&1 == "displayName"))

      assert id_index < deleted_index
      assert deleted_index < display_index
    end

    test "flattens group (two-level inheritance)", %{metadata: metadata} do
      group = TypeResolver.resolve_entity("group", metadata)
      prop_names = Enum.map(group.properties, & &1.name)

      assert "id" in prop_names
      assert "deletedDateTime" in prop_names
      assert "displayName" in prop_names
      assert "mailEnabled" in prop_names
    end

    test "flattens message (single-level inheritance)", %{metadata: metadata} do
      message = TypeResolver.resolve_entity("message", metadata)
      prop_names = Enum.map(message.properties, & &1.name)

      assert "id" in prop_names
      assert "subject" in prop_names
      assert "body" in prop_names
    end
  end

  describe "resolve/2" do
    test "resolves requested entities", %{metadata: metadata} do
      result = TypeResolver.resolve(metadata, ["user", "group"])
      entity_names = Enum.map(result.entities, & &1.name)

      assert "user" in entity_names
      assert "group" in entity_names
      assert length(result.entities) == 2
    end

    test "discovers referenced complex types", %{metadata: metadata} do
      result = TypeResolver.resolve(metadata, ["user"])
      complex_names = Enum.map(result.complex_types, & &1.name)

      # Direct: passwordProfile, assignedLicense
      assert "passwordProfile" in complex_names
      assert "assignedLicense" in complex_names
    end

    test "discovers transitively referenced complex types", %{metadata: metadata} do
      # message -> body: itemBody -> contentType: bodyType (enum)
      # message -> from: recipient -> emailAddress: emailAddress (complex)
      result = TypeResolver.resolve(metadata, ["message"])
      complex_names = Enum.map(result.complex_types, & &1.name)

      assert "itemBody" in complex_names
      assert "recipient" in complex_names
      assert "emailAddress" in complex_names
    end

    test "discovers referenced enum types", %{metadata: metadata} do
      result = TypeResolver.resolve(metadata, ["message"])
      enum_names = Enum.map(result.enum_types, & &1.name)

      assert "importance" in enum_names
      # bodyType is referenced by itemBody which is referenced by message
      assert "bodyType" in enum_names
    end

    test "skips unknown entity names", %{metadata: metadata} do
      result = TypeResolver.resolve(metadata, ["user", "nonexistent"])
      assert length(result.entities) == 1
    end

    test "deduplicates complex types across entities", %{metadata: metadata} do
      # Both message and event reference recipient and itemBody
      result = TypeResolver.resolve(metadata, ["message", "event"])
      complex_names = Enum.map(result.complex_types, & &1.name)

      recipient_count = Enum.count(complex_names, &(&1 == "recipient"))
      assert recipient_count == 1
    end
  end

  describe "extract_graph_types/1" do
    test "extracts type from microsoft.graph reference" do
      assert TypeResolver.extract_graph_types("microsoft.graph.passwordProfile") ==
               ["passwordProfile"]
    end

    test "extracts type from collection of graph type" do
      assert TypeResolver.extract_graph_types("Collection(microsoft.graph.assignedLicense)") ==
               ["assignedLicense"]
    end

    test "returns empty for Edm primitives" do
      assert TypeResolver.extract_graph_types("Edm.String") == []
      assert TypeResolver.extract_graph_types("Edm.Boolean") == []
      assert TypeResolver.extract_graph_types("Edm.Int32") == []
    end

    test "returns empty for collection of Edm primitives" do
      assert TypeResolver.extract_graph_types("Collection(Edm.String)") == []
      assert TypeResolver.extract_graph_types("Collection(Edm.Guid)") == []
    end
  end
end
