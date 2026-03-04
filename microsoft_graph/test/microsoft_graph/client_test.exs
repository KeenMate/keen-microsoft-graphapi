defmodule MicrosoftGraph.ClientTest do
  # async: false because tests temporarily modify Application env
  use ExUnit.Case, async: false

  alias MicrosoftGraph.Client
  alias MicrosoftGraph.Config

  @config Config.new!(
            tenant_id: "test-tenant",
            client_id: "test-client",
            client_secret: "test-secret"
          )

  describe "new/1 with config" do
    test "creates a Req.Request with base_url from config" do
      client = Client.new(config: @config)
      assert %Req.Request{} = client
      assert to_string(client.options[:base_url]) =~ "graph.microsoft.com/v1.0"
    end

    test "attaches microsoft_graph_config option" do
      client = Client.new(config: @config)
      assert client.options[:microsoft_graph_config] == @config
    end

    test "sets json content-type header" do
      client = Client.new(config: @config)

      assert Enum.any?(client.headers, fn
               {key, _} -> key == "content-type"
             end)
    end

    test "accepts custom token_store" do
      client = Client.new(config: @config, token_store: :custom_store)
      assert client.options[:microsoft_graph_token_store] == :custom_store
    end
  end

  describe "new/1 with beta config" do
    test "uses beta base_url from config" do
      config =
        Config.new!(
          tenant_id: "test-tenant",
          client_id: "test-client",
          client_secret: "test-secret",
          api_version: :beta
        )

      client = Client.new(config: config)
      assert to_string(client.options[:base_url]) =~ "graph.microsoft.com/beta"
    end
  end

  describe "new/1 without config (delegated)" do
    test "creates client without config when env is not set" do
      # Temporarily remove the app env config
      original = Application.get_env(:microsoft_graph, :config)
      Application.delete_env(:microsoft_graph, :config)

      try do
        client = Client.new()
        assert %Req.Request{} = client
        assert client.options[:microsoft_graph_config] == nil
        assert to_string(client.options[:base_url]) =~ "graph.microsoft.com/v1.0"
      after
        if original, do: Application.put_env(:microsoft_graph, :config, original)
      end
    end

    test "accepts api_version without config" do
      original = Application.get_env(:microsoft_graph, :config)
      Application.delete_env(:microsoft_graph, :config)

      try do
        client = Client.new(api_version: :beta)
        assert to_string(client.options[:base_url]) =~ "graph.microsoft.com/beta"
      after
        if original, do: Application.put_env(:microsoft_graph, :config, original)
      end
    end

    test "registers access_token as valid option" do
      client = Client.new(config: @config)
      # access_token should be registered, so setting it should not raise
      assert %Req.Request{} = Req.Request.put_option(client, :access_token, "test-token")
    end
  end
end
