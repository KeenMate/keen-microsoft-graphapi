if Code.ensure_loaded?(SweetXml) do
defmodule GraphApi.Schema.Generator.MetadataParser do
  @moduledoc false
  # Parses OData CSDL XML ($metadata) via SweetXml into structured maps.
  #
  # Returns a map with three keys:
  #   - :entity_types - map of entity name => %{name, base_type, properties, nav_properties}
  #   - :complex_types - map of complex type name => %{name, properties}
  #   - :enum_types - map of enum name => %{name, members}

  import SweetXml

  @doc """
  Parses an OData CSDL XML string and returns structured metadata.

  Returns `%{entity_types: %{}, complex_types: %{}, enum_types: %{}}`.
  """
  @spec parse(String.t()) :: %{
          entity_types: map(),
          complex_types: map(),
          enum_types: map()
        }
  def parse(xml_string) when is_binary(xml_string) do
    doc = SweetXml.parse(xml_string)

    %{
      entity_types: parse_entity_types(doc),
      complex_types: parse_complex_types(doc),
      enum_types: parse_enum_types(doc)
    }
  end

  defp parse_entity_types(doc) do
    doc
    |> xpath(~x"//Schema/EntityType"l)
    |> Enum.map(&parse_entity_type/1)
    |> Map.new(fn et -> {et.name, et} end)
  end

  defp parse_entity_type(node) do
    name = xpath(node, ~x"./@Name"s)
    base_type = xpath(node, ~x"./@BaseType"s)

    properties =
      node
      |> xpath(~x"./Property"l)
      |> Enum.map(&parse_property/1)

    nav_properties =
      node
      |> xpath(~x"./NavigationProperty"l)
      |> Enum.map(&parse_nav_property/1)

    %{
      name: name,
      base_type: if(base_type == "", do: nil, else: base_type),
      properties: properties,
      nav_properties: nav_properties
    }
  end

  defp parse_complex_types(doc) do
    doc
    |> xpath(~x"//Schema/ComplexType"l)
    |> Enum.map(&parse_complex_type/1)
    |> Map.new(fn ct -> {ct.name, ct} end)
  end

  defp parse_complex_type(node) do
    name = xpath(node, ~x"./@Name"s)

    properties =
      node
      |> xpath(~x"./Property"l)
      |> Enum.map(&parse_property/1)

    %{name: name, properties: properties}
  end

  defp parse_enum_types(doc) do
    doc
    |> xpath(~x"//Schema/EnumType"l)
    |> Enum.map(&parse_enum_type/1)
    |> Map.new(fn et -> {et.name, et} end)
  end

  defp parse_enum_type(node) do
    name = xpath(node, ~x"./@Name"s)

    members =
      node
      |> xpath(~x"./Member"l)
      |> Enum.map(fn member ->
        %{
          name: xpath(member, ~x"./@Name"s),
          value: xpath(member, ~x"./@Value"s)
        }
      end)

    %{name: name, members: members}
  end

  defp parse_property(node) do
    %{
      name: xpath(node, ~x"./@Name"s),
      type: xpath(node, ~x"./@Type"s)
    }
  end

  defp parse_nav_property(node) do
    %{
      name: xpath(node, ~x"./@Name"s),
      type: xpath(node, ~x"./@Type"s)
    }
  end
end
end
