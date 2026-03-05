defmodule GraphApi.Test.EnvLoader do
  @moduledoc """
  Loads environment variables from a `.env.test` file at the project root.

  Lines starting with `#` are ignored. Blank lines are ignored.
  Format: `KEY=value` (no quoting needed, values are trimmed).
  """

  @doc """
  Loads `.env.test` into `System` environment variables.
  Only sets variables that are not already set, so real env vars take priority.
  Returns `:ok` or `{:error, :not_found}` if the file doesn't exist.
  """
  @spec load() :: :ok | {:error, :not_found}
  def load do
    path = Path.join(File.cwd!(), ".env.test")

    if File.exists?(path) do
      path
      |> File.read!()
      |> String.split("\n")
      |> Enum.each(&parse_and_set/1)

      :ok
    else
      {:error, :not_found}
    end
  end

  defp parse_and_set(line) do
    line = String.trim(line)

    case line do
      "" -> :skip
      "#" <> _ -> :skip
      _ -> do_parse(line)
    end
  end

  defp do_parse(line) do
    case String.split(line, "=", parts: 2) do
      [key, value] ->
        key = String.trim(key)
        value = String.trim(value)

        # Don't override existing env vars
        if System.get_env(key) == nil do
          System.put_env(key, value)
        end

      _ ->
        :skip
    end
  end
end
