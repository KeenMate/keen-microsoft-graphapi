defmodule GraphApi.Schema.Generator.Naming do
  @moduledoc false
  # Naming conventions for converting between OData/camelCase and Elixir/snake_case.

  @doc """
  Converts a camelCase or PascalCase string to snake_case.

  ## Examples

      iex> camel_to_snake("displayName")
      "display_name"

      iex> camel_to_snake("userPrincipalName")
      "user_principal_name"

      iex> camel_to_snake("id")
      "id"

      iex> camel_to_snake("SMTPAddress")
      "smtp_address"
  """
  @spec camel_to_snake(String.t()) :: String.t()
  def camel_to_snake(string) when is_binary(string) do
    string
    |> String.replace(~r/([A-Z]+)([A-Z][a-z])/, "\\1_\\2")
    |> String.replace(~r/([a-z\d])([A-Z])/, "\\1_\\2")
    |> String.downcase()
  end

  @doc """
  Converts a snake_case string to camelCase.

  ## Examples

      iex> snake_to_camel("display_name")
      "displayName"

      iex> snake_to_camel("id")
      "id"
  """
  @spec snake_to_camel(String.t()) :: String.t()
  def snake_to_camel(string) when is_binary(string) do
    [first | rest] = String.split(string, "_")
    Enum.join([first | Enum.map(rest, &String.capitalize/1)])
  end

  @doc """
  Converts an OData entity type name to an Elixir module name string.

  ## Examples

      iex> entity_to_module_name("user")
      "User"

      iex> entity_to_module_name("driveItem")
      "DriveItem"

      iex> entity_to_module_name("mailFolder")
      "MailFolder"

      iex> entity_to_module_name("passwordProfile")
      "PasswordProfile"
  """
  @spec entity_to_module_name(String.t()) :: String.t()
  def entity_to_module_name(name) when is_binary(name) do
    name
    |> String.replace(~r/([a-z])([A-Z])/, "\\1_\\2")
    |> String.split("_")
    |> Enum.map_join(&String.capitalize/1)
  end

  @doc """
  Converts a fully qualified OData type like `microsoft.graph.user` to just the type name.

  ## Examples

      iex> extract_type_name("microsoft.graph.user")
      "user"

      iex> extract_type_name("microsoft.graph.passwordProfile")
      "passwordProfile"
  """
  @spec extract_type_name(String.t()) :: String.t()
  def extract_type_name(fqn) when is_binary(fqn) do
    fqn |> String.split(".") |> List.last()
  end

  @doc """
  Converts a property name (camelCase) to a struct field atom (snake_case).

  ## Examples

      iex> property_to_field("displayName")
      :display_name

      iex> property_to_field("id")
      :id
  """
  @spec property_to_field(String.t()) :: atom()
  def property_to_field(name) when is_binary(name) do
    name |> camel_to_snake() |> String.to_atom()
  end
end
