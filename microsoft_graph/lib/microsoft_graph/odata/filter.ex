defmodule MicrosoftGraph.OData.Filter do
  @moduledoc """
  Schema-aware OData filter builder.

  Translates snake_case Elixir field names to camelCase API field names
  using schema module field mappings, and builds valid OData `$filter` expressions.

  ## Simple keyword syntax

  For equality conditions combined with `and`:

      OData.new()
      |> OData.filter(User, department: "Engineering", account_enabled: true)
      # => $filter=department eq 'Engineering' and accountEnabled eq true

  ## Builder syntax

  For complex filters with different operators:

      alias MicrosoftGraph.OData.Filter

      filter =
        Filter.new(User)
        |> Filter.where(:display_name, :starts_with, "A")
        |> Filter.where(:account_enabled, :eq, true)
        |> Filter.or_where(:department, :eq, "Sales")

      OData.new() |> OData.filter(filter)

  ## Supported operators

  - `:eq`, `:ne` — equality / inequality
  - `:gt`, `:lt`, `:ge`, `:le` — comparison
  - `:starts_with`, `:ends_with`, `:contains` — string functions
  - `:in` — collection membership
  - `:is_nil` — null check (use `true` for `eq null`, `false` for `ne null`)
  """

  defstruct schema: nil, clauses: []

  @type operator ::
          :eq | :ne | :gt | :lt | :ge | :le
          | :starts_with | :ends_with | :contains
          | :in | :is_nil

  @type t :: %__MODULE__{
          schema: module(),
          clauses: [{:and | :or, atom(), operator(), term()}]
        }

  @doc """
  Creates a new filter builder for the given schema module.
  """
  @spec new(module()) :: t()
  def new(schema) when is_atom(schema) do
    %__MODULE__{schema: schema}
  end

  @doc """
  Adds an AND condition to the filter.

  ## Examples

      Filter.new(User)
      |> Filter.where(:display_name, :eq, "Alice")
      |> Filter.where(:account_enabled, :eq, true)
  """
  @spec where(t(), atom(), operator(), term()) :: t()
  def where(%__MODULE__{} = filter, field, op, value) do
    %{filter | clauses: filter.clauses ++ [{:and, field, op, value}]}
  end

  @doc """
  Adds an OR condition to the filter.

  ## Examples

      Filter.new(User)
      |> Filter.where(:department, :eq, "Engineering")
      |> Filter.or_where(:department, :eq, "Sales")
  """
  @spec or_where(t(), atom(), operator(), term()) :: t()
  def or_where(%__MODULE__{} = filter, field, op, value) do
    %{filter | clauses: filter.clauses ++ [{:or, field, op, value}]}
  end

  @doc """
  Builds a filter string from simple keyword conditions (all AND-ed with `eq`).

  Used by `OData.filter/3`. Each key is a snake_case field name, each value
  is compared with `eq`.

  ## Examples

      Filter.from_keywords(User, department: "Engineering", account_enabled: true)
      #=> "department eq 'Engineering' and accountEnabled eq true"
  """
  @spec from_keywords(module(), keyword()) :: String.t()
  def from_keywords(schema, conditions) when is_atom(schema) and is_list(conditions) do
    reverse_map = build_reverse_map(schema)

    conditions
    |> Enum.map(fn {field, value} ->
      api_name = resolve_field!(reverse_map, field)
      "#{api_name} eq #{encode_value(value)}"
    end)
    |> Enum.join(" and ")
  end

  @doc """
  Converts the filter builder to an OData filter string.

  ## Examples

      Filter.new(User)
      |> Filter.where(:display_name, :starts_with, "A")
      |> Filter.where(:account_enabled, :eq, true)
      |> Filter.to_string()
      #=> "startsWith(displayName,'A') and accountEnabled eq true"
  """
  @spec to_string(t()) :: String.t()
  def to_string(%__MODULE__{schema: schema, clauses: clauses}) do
    reverse_map = build_reverse_map(schema)

    clauses
    |> Enum.with_index()
    |> Enum.map(fn {{join, field, op, value}, index} ->
      expr = build_expression(reverse_map, field, op, value)

      if index == 0 do
        expr
      else
        case join do
          :and -> " and #{expr}"
          :or -> " or #{expr}"
        end
      end
    end)
    |> IO.iodata_to_binary()
  end

  # Allow Filter structs to be used directly as strings via String.Chars
  defimpl String.Chars do
    def to_string(%MicrosoftGraph.OData.Filter{} = filter) do
      MicrosoftGraph.OData.Filter.to_string(filter)
    end
  end

  # -- Internal --

  defp build_expression(reverse_map, field, op, value) do
    api_name = resolve_field!(reverse_map, field)

    case op do
      :eq -> "#{api_name} eq #{encode_value(value)}"
      :ne -> "#{api_name} ne #{encode_value(value)}"
      :gt -> "#{api_name} gt #{encode_value(value)}"
      :lt -> "#{api_name} lt #{encode_value(value)}"
      :ge -> "#{api_name} ge #{encode_value(value)}"
      :le -> "#{api_name} le #{encode_value(value)}"
      :starts_with -> "startsWith(#{api_name},#{encode_value(value)})"
      :ends_with -> "endsWith(#{api_name},#{encode_value(value)})"
      :contains -> "contains(#{api_name},#{encode_value(value)})"
      :in -> "#{api_name} in (#{encode_collection(value)})"
      :is_nil when value == true -> "#{api_name} eq null"
      :is_nil when value == false -> "#{api_name} ne null"
    end
  end

  defp encode_value(nil), do: "null"
  defp encode_value(true), do: "true"
  defp encode_value(false), do: "false"
  defp encode_value(value) when is_integer(value), do: Integer.to_string(value)
  defp encode_value(value) when is_float(value), do: Float.to_string(value)
  defp encode_value(value) when is_binary(value), do: "'#{escape_string(value)}'"

  defp encode_collection(values) when is_list(values) do
    values |> Enum.map(&encode_value/1) |> Enum.join(",")
  end

  defp escape_string(str), do: String.replace(str, "'", "''")

  defp build_reverse_map(schema) do
    schema.__field_mapping__()
    |> Enum.into(%{}, fn {api_name, atom_name} -> {atom_name, api_name} end)
  end

  defp resolve_field!(reverse_map, field) do
    case Map.get(reverse_map, field) do
      nil ->
        raise ArgumentError,
              "unknown field #{inspect(field)} — not found in schema field mapping"

      api_name ->
        api_name
    end
  end
end
