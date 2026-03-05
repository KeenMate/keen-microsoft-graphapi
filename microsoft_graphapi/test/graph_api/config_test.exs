defmodule GraphApi.ConfigTest do
  use ExUnit.Case, async: true

  alias GraphApi.Config

  @valid_opts [
    tenant_id: "test-tenant",
    client_id: "test-client",
    client_secret: "test-secret"
  ]

  describe "new/1" do
    test "creates config with valid required options" do
      assert {:ok, config} = Config.new(@valid_opts)
      assert config.tenant_id == "test-tenant"
      assert config.client_id == "test-client"
      assert config.client_secret == "test-secret"
    end

    test "sets default scope" do
      assert {:ok, config} = Config.new(@valid_opts)
      assert config.scope == "https://graph.microsoft.com/.default"
    end

    test "sets default base_url from v1" do
      assert {:ok, config} = Config.new(@valid_opts)
      assert config.base_url == "https://graph.microsoft.com/v1.0"
      assert config.api_version == :v1
    end

    test "sets beta base_url when api_version is :beta" do
      opts = Keyword.put(@valid_opts, :api_version, :beta)
      assert {:ok, config} = Config.new(opts)
      assert config.base_url == "https://graph.microsoft.com/beta"
      assert config.api_version == :beta
    end

    test "allows overriding scope" do
      opts = Keyword.put(@valid_opts, :scope, "custom-scope")
      assert {:ok, config} = Config.new(opts)
      assert config.scope == "custom-scope"
    end

    test "allows overriding base_url (takes priority over api_version)" do
      opts =
        @valid_opts
        |> Keyword.put(:base_url, "https://custom.example.com/graph")
        |> Keyword.put(:api_version, :beta)

      assert {:ok, config} = Config.new(opts)
      assert config.base_url == "https://custom.example.com/graph"
    end

    test "returns error when tenant_id is missing" do
      opts = Keyword.delete(@valid_opts, :tenant_id)
      assert {:error, %NimbleOptions.ValidationError{}} = Config.new(opts)
    end

    test "returns error when client_id is missing" do
      opts = Keyword.delete(@valid_opts, :client_id)
      assert {:error, %NimbleOptions.ValidationError{}} = Config.new(opts)
    end

    test "returns error when client_secret is missing" do
      opts = Keyword.delete(@valid_opts, :client_secret)
      assert {:error, %NimbleOptions.ValidationError{}} = Config.new(opts)
    end

    test "returns error for invalid option type" do
      opts = Keyword.put(@valid_opts, :tenant_id, 123)
      assert {:error, %NimbleOptions.ValidationError{}} = Config.new(opts)
    end

    test "returns error for invalid api_version" do
      opts = Keyword.put(@valid_opts, :api_version, :v2)
      assert {:error, %NimbleOptions.ValidationError{}} = Config.new(opts)
    end
  end

  describe "new!/1" do
    test "creates config with valid options" do
      config = Config.new!(@valid_opts)
      assert %Config{} = config
      assert config.tenant_id == "test-tenant"
    end

    test "raises on invalid options" do
      assert_raise NimbleOptions.ValidationError, fn ->
        Config.new!([])
      end
    end
  end

  describe "from_env!/0" do
    test "reads config from application environment" do
      config = Config.from_env!()
      assert %Config{} = config
      assert config.tenant_id == "test-tenant-id"
      assert config.client_id == "test-client-id"
      assert config.client_secret == "test-client-secret"
    end
  end

  describe "base_url_for/1" do
    test "returns v1.0 URL" do
      assert Config.base_url_for(:v1) == "https://graph.microsoft.com/v1.0"
    end

    test "returns beta URL" do
      assert Config.base_url_for(:beta) == "https://graph.microsoft.com/beta"
    end
  end
end
