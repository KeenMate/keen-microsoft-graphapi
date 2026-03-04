defmodule MicrosoftGraph.View do
  @moduledoc """
  Macro for defining view structs that project a subset of fields from a schema module.

  Views provide IDE autocomplete, automatic `$select` injection, and compile-time
  field validation against the parent schema.

  ## Usage

      defmodule MyApp.UserSummary do
        use MicrosoftGraph.View,
          schema: MicrosoftGraph.Schema.User,
          fields: [:id, :display_name, :mail, :job_title]
      end

  This generates:

  - `defstruct` with only the listed fields
  - `from_map/1` — casts via parent schema's `from_map/1`, then takes only view fields
  - `to_map/1` — converts back to camelCase via parent schema
  - `__select__/0` — returns camelCase field names for auto `$select` injection
  - `__schema__/0` — returns the parent schema module
  """

  defmacro __using__(opts) do
    schema = Keyword.fetch!(opts, :schema)
    fields = Keyword.fetch!(opts, :fields)

    quote do
      @schema unquote(schema)
      @view_fields unquote(fields)

      # Compile-time validation: ensure all view fields exist on the schema
      schema_fields = @schema.__struct__() |> Map.keys() |> MapSet.new()

      Enum.each(@view_fields, fn field ->
        unless MapSet.member?(schema_fields, field) do
          raise CompileError,
            description:
              "field #{inspect(field)} does not exist on schema #{inspect(@schema)}. " <>
                "Available fields: #{inspect(MapSet.to_list(schema_fields) -- [:__struct__])}"
        end
      end)

      defstruct @view_fields

      @type t :: %__MODULE__{}

      # Build the select list at compile time
      @select_fields (
                       field_mapping = @schema.__field_mapping__()
                       reverse = Map.new(field_mapping, fn {k, v} -> {v, k} end)

                       Enum.map(@view_fields, fn field ->
                         Map.fetch!(reverse, field)
                       end)
                     )

      @doc "Returns the list of camelCase field names for OData `$select`."
      @spec __select__() :: [String.t()]
      def __select__, do: @select_fields

      @doc "Returns the parent schema module."
      @spec __schema__() :: module()
      def __schema__, do: @schema

      @doc "Converts a camelCase string-key map into this view struct."
      @spec from_map(map()) :: t()
      def from_map(map) when is_map(map) do
        full = @schema.from_map(map)
        struct(__MODULE__, Map.take(Map.from_struct(full), @view_fields))
      end

      @doc "Converts this view struct to a camelCase string-key map. Nil fields are omitted."
      @spec to_map(t()) :: map()
      def to_map(%__MODULE__{} = view) do
        view_map = Map.from_struct(view)
        full = struct(@schema, view_map)
        @schema.to_map(full)
      end
    end
  end
end
