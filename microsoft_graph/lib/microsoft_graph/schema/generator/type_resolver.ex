defmodule MicrosoftGraph.Schema.Generator.TypeResolver do
  @moduledoc false
  # Walks BaseType inheritance chains, flattens properties, and discovers
  # referenced complex/enum types needed for code generation.

  alias MicrosoftGraph.Schema.Generator.Naming

  @doc """
  Resolves a set of requested entity types from parsed metadata.

  For each entity name:
  1. Walks the inheritance chain (BaseType) and flattens all properties
  2. Discovers all referenced complex types and enum types (recursively)

  Returns `%{entities: [...], complex_types: [...], enum_types: [...]}` where each
  entry is a resolved type with flattened properties.
  """
  @spec resolve(metadata :: map(), entity_names :: [String.t()]) :: %{
          entities: [map()],
          complex_types: [map()],
          enum_types: [map()]
        }
  def resolve(metadata, entity_names) do
    entities =
      entity_names
      |> Enum.filter(&Map.has_key?(metadata.entity_types, &1))
      |> Enum.map(&resolve_entity(&1, metadata))

    # Collect all referenced complex and enum types
    all_type_refs = collect_type_refs(entities, metadata)

    complex_types =
      all_type_refs.complex
      |> Enum.map(fn name ->
        ct = Map.fetch!(metadata.complex_types, name)
        %{name: ct.name, properties: ct.properties}
      end)

    enum_types =
      all_type_refs.enum
      |> Enum.map(fn name -> Map.fetch!(metadata.enum_types, name) end)

    %{
      entities: entities,
      complex_types: complex_types,
      enum_types: enum_types
    }
  end

  @doc """
  Resolves a single entity by flattening its inheritance chain.

  Returns the entity map with all inherited properties merged (parent properties first).
  """
  @spec resolve_entity(String.t(), map()) :: map()
  def resolve_entity(name, metadata) do
    entity = Map.fetch!(metadata.entity_types, name)
    chain = build_inheritance_chain(entity, metadata.entity_types, [])

    all_properties =
      chain
      |> Enum.flat_map(& &1.properties)

    %{
      name: entity.name,
      properties: all_properties
    }
  end

  # Builds the inheritance chain from root to the given entity (inclusive).
  # Returns list ordered from root ancestor to the entity itself.
  defp build_inheritance_chain(%{base_type: nil} = entity, _entity_types, acc) do
    [entity | acc]
  end

  defp build_inheritance_chain(%{base_type: base_fqn} = entity, entity_types, acc) do
    base_name = Naming.extract_type_name(base_fqn)

    case Map.get(entity_types, base_name) do
      nil -> [entity | acc]
      parent -> build_inheritance_chain(parent, entity_types, [entity | acc])
    end
  end

  # Recursively collects all complex and enum type names referenced by a set of entities.
  defp collect_type_refs(entities, metadata) do
    initial_refs =
      entities
      |> Enum.flat_map(& &1.properties)
      |> Enum.flat_map(&extract_graph_types(&1.type))
      |> MapSet.new()

    resolve_transitive_refs(initial_refs, MapSet.new(), MapSet.new(), metadata)
  end

  defp resolve_transitive_refs(pending, visited_complex, visited_enum, metadata) do
    if MapSet.size(pending) == 0 do
      %{complex: MapSet.to_list(visited_complex), enum: MapSet.to_list(visited_enum)}
    else
      {new_complex, new_enum} =
        Enum.reduce(pending, {visited_complex, visited_enum}, fn type_name, {cx, en} ->
          cond do
            Map.has_key?(metadata.complex_types, type_name) ->
              {MapSet.put(cx, type_name), en}

            Map.has_key?(metadata.enum_types, type_name) ->
              {cx, MapSet.put(en, type_name)}

            true ->
              {cx, en}
          end
        end)

      # Find newly discovered complex types and extract their refs
      newly_added_complex = MapSet.difference(new_complex, visited_complex)

      child_refs =
        newly_added_complex
        |> Enum.flat_map(fn name ->
          ct = Map.fetch!(metadata.complex_types, name)
          Enum.flat_map(ct.properties, &extract_graph_types(&1.type))
        end)
        |> MapSet.new()

      already_seen = MapSet.union(new_complex, new_enum)
      next_pending = MapSet.difference(child_refs, already_seen)

      resolve_transitive_refs(next_pending, new_complex, new_enum, metadata)
    end
  end

  @doc """
  Extracts the graph type name(s) from an OData type string.

  Returns a list of type names (without "microsoft.graph." prefix).
  Returns empty list for Edm primitive types.

  ## Examples

      iex> extract_graph_types("microsoft.graph.passwordProfile")
      ["passwordProfile"]

      iex> extract_graph_types("Collection(microsoft.graph.assignedLicense)")
      ["assignedLicense"]

      iex> extract_graph_types("Edm.String")
      []

      iex> extract_graph_types("Collection(Edm.String)")
      []
  """
  @spec extract_graph_types(String.t()) :: [String.t()]
  def extract_graph_types("Collection(" <> rest) do
    inner = String.trim_trailing(rest, ")")
    extract_graph_types(inner)
  end

  def extract_graph_types("microsoft.graph." <> name), do: [name]
  def extract_graph_types("Edm." <> _), do: []
  def extract_graph_types(_), do: []
end
