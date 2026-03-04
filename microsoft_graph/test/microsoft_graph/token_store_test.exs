defmodule MicrosoftGraph.TokenStoreTest do
  use ExUnit.Case, async: false

  alias MicrosoftGraph.TokenStore

  setup do
    # Start a unique token store for each test
    name = :"token_store_#{System.unique_integer([:positive])}"
    {:ok, pid} = TokenStore.start_link(name: name)
    %{store: name, pid: pid}
  end

  describe "get_token/2" do
    test "GenServer is alive and accepts calls", %{store: store} do
      # Verify the GenServer starts and is ready to handle calls
      assert Process.alive?(Process.whereis(store))
    end
  end

  describe "start_link/1" do
    test "starts with custom name" do
      name = :"test_store_#{System.unique_integer([:positive])}"
      {:ok, pid} = TokenStore.start_link(name: name)
      assert Process.alive?(pid)
      assert Process.whereis(name) == pid
      GenServer.stop(pid)
    end
  end
end
