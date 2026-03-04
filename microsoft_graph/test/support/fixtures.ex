defmodule MicrosoftGraph.Test.Fixtures do
  @moduledoc """
  Helper for loading JSON fixture files in tests.
  """

  @fixtures_path Path.expand("../fixtures", __DIR__)

  @doc """
  Loads and decodes a JSON fixture file.

  ## Examples

      Fixtures.load("users/list.json")
      Fixtures.load("auth/token_success.json")
  """
  @spec load(String.t()) :: map() | list()
  def load(path) do
    @fixtures_path
    |> Path.join(path)
    |> File.read!()
    |> Jason.decode!()
  end

  @doc """
  Returns the raw string content of a fixture file.
  """
  @spec load_raw(String.t()) :: String.t()
  def load_raw(path) do
    @fixtures_path
    |> Path.join(path)
    |> File.read!()
  end
end
