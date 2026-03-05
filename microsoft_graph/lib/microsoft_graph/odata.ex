defmodule MicrosoftGraph.OData do
  @moduledoc """
  Functional builder for OData query parameters.

  Builds `$select`, `$filter`, `$expand`, `$top`, `$skip`, `$orderby`,
  `$count`, and `$search` query parameters for Microsoft Graph API requests.

  ## Examples

      alias MicrosoftGraph.OData

      query = OData.new()
        |> OData.select(["displayName", "mail", "id"])
        |> OData.filter("department eq 'Engineering'")
        |> OData.top(25)
        |> OData.orderby("displayName")

      params = OData.to_params(query)
      # %{"$select" => "displayName,mail,id", "$filter" => "department eq 'Engineering'", ...}

  The `$filter` value is a raw string — Graph filter syntax is too varied for a DSL.
  """

  @type t :: %__MODULE__{
          select: [String.t()] | nil,
          filter: String.t() | nil,
          expand: [String.t()] | nil,
          top: pos_integer() | nil,
          skip: non_neg_integer() | nil,
          orderby: String.t() | nil,
          count: boolean() | nil,
          search: String.t() | nil
        }

  defstruct select: nil,
            filter: nil,
            expand: nil,
            top: nil,
            skip: nil,
            orderby: nil,
            count: nil,
            search: nil

  @doc """
  Creates a new empty OData query builder.
  """
  @spec new() :: t()
  def new, do: %__MODULE__{}

  @doc """
  Sets `$select` fields. Accepts a list of field name strings.

  ## Examples

      OData.new() |> OData.select(["displayName", "mail"])
  """
  @spec select(t(), [String.t()]) :: t()
  def select(%__MODULE__{} = query, fields) when is_list(fields) do
    %{query | select: fields}
  end

  @doc """
  Sets the `$filter` expression.

  Accepts a raw OData filter string, a `Filter` struct, or a schema module
  with keyword conditions for schema-aware filtering.

  ## Examples

      # Raw string
      OData.new() |> OData.filter("startsWith(displayName, 'A')")

      # Schema-aware keyword syntax (equality, AND-ed)
      OData.new() |> OData.filter(User, department: "Engineering", account_enabled: true)

      # Filter builder struct
      filter = Filter.new(User) |> Filter.where(:display_name, :starts_with, "A")
      OData.new() |> OData.filter(filter)
  """
  @spec filter(t(), String.t() | MicrosoftGraph.OData.Filter.t()) :: t()
  def filter(%__MODULE__{} = query, %MicrosoftGraph.OData.Filter{} = filter_builder) do
    %{query | filter: MicrosoftGraph.OData.Filter.to_string(filter_builder)}
  end

  def filter(%__MODULE__{} = query, expression) when is_binary(expression) do
    %{query | filter: expression}
  end

  @doc """
  Sets the `$filter` expression using a schema module and keyword conditions.

  Each keyword is a snake_case field name from the schema, matched with `eq`.
  Multiple conditions are combined with `and`.

  ## Examples

      alias MicrosoftGraph.Schema.User

      OData.new()
      |> OData.filter(User, department: "Engineering", account_enabled: true)
      # => $filter=department eq 'Engineering' and accountEnabled eq true
  """
  @spec filter(t(), module(), keyword()) :: t()
  def filter(%__MODULE__{} = query, schema, conditions)
      when is_atom(schema) and is_list(conditions) do
    %{query | filter: MicrosoftGraph.OData.Filter.from_keywords(schema, conditions)}
  end

  @doc """
  Sets `$expand` fields. Accepts a list of relationship names.

  ## Examples

      OData.new() |> OData.expand(["manager", "directReports"])
  """
  @spec expand(t(), [String.t()]) :: t()
  def expand(%__MODULE__{} = query, fields) when is_list(fields) do
    %{query | expand: fields}
  end

  @doc """
  Sets `$top` (page size). Must be a positive integer.

  ## Examples

      OData.new() |> OData.top(25)
  """
  @spec top(t(), pos_integer()) :: t()
  def top(%__MODULE__{} = query, n) when is_integer(n) and n > 0 do
    %{query | top: n}
  end

  @doc """
  Sets `$skip` (offset). Must be a non-negative integer.

  ## Examples

      OData.new() |> OData.skip(50)
  """
  @spec skip(t(), non_neg_integer()) :: t()
  def skip(%__MODULE__{} = query, n) when is_integer(n) and n >= 0 do
    %{query | skip: n}
  end

  @doc """
  Sets `$orderby` expression.

  ## Examples

      OData.new() |> OData.orderby("displayName desc")
  """
  @spec orderby(t(), String.t()) :: t()
  def orderby(%__MODULE__{} = query, expression) when is_binary(expression) do
    %{query | orderby: expression}
  end

  @doc """
  Sets `$count` to true, requesting an inline count of matching resources.

  ## Examples

      OData.new() |> OData.count()
  """
  @spec count(t()) :: t()
  def count(%__MODULE__{} = query) do
    %{query | count: true}
  end

  @doc """
  Sets `$search` expression.

  ## Examples

      OData.new() |> OData.search("\"displayName:John\"")
  """
  @spec search(t(), String.t()) :: t()
  def search(%__MODULE__{} = query, expression) when is_binary(expression) do
    %{query | search: expression}
  end

  @doc """
  Converts the OData query builder to a map of query parameters.

  Only includes parameters that have been set (non-nil).
  Lists are joined with commas. Booleans are converted to strings.

  ## Examples

      OData.new()
      |> OData.select(["id", "displayName"])
      |> OData.top(10)
      |> OData.to_params()
      #=> %{"$select" => "id,displayName", "$top" => "10"}
  """
  @spec to_params(t()) :: map()
  def to_params(%__MODULE__{} = query) do
    []
    |> maybe_add("$select", query.select, &Enum.join(&1, ","))
    |> maybe_add("$filter", query.filter)
    |> maybe_add("$expand", query.expand, &Enum.join(&1, ","))
    |> maybe_add("$top", query.top, &to_string/1)
    |> maybe_add("$skip", query.skip, &to_string/1)
    |> maybe_add("$orderby", query.orderby)
    |> maybe_add("$count", query.count, &to_string/1)
    |> maybe_add("$search", query.search)
    |> Map.new()
  end

  defp maybe_add(acc, _key, nil), do: acc
  defp maybe_add(acc, key, value), do: [{key, value} | acc]
  defp maybe_add(acc, _key, nil, _transform), do: acc
  defp maybe_add(acc, key, value, transform), do: [{key, transform.(value)} | acc]
end
