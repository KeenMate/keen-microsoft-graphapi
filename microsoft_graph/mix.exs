defmodule GraphApi.MixProject do
  use Mix.Project

  @version "1.0.0-rc.1"
  @source_url "https://github.com/keenmate/microsoft_graph"

  def project do
    [
      app: :keen_microsoft_graphapi,
      version: @version,
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      elixirc_paths: elixirc_paths(Mix.env()),
      name: "GraphApi",
      description: "Elixir client for the Microsoft Graph API",
      package: package(),
      docs: docs(),
      source_url: @source_url,
      dialyzer: [plt_add_apps: [:mix]]
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {GraphApi.Application, []}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:req, "~> 0.5"},
      {:jason, "~> 1.4"},
      {:nimble_options, "~> 1.0"},
      {:plug, "~> 1.0", optional: true},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false},
      {:sweet_xml, "~> 0.7", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false}
    ]
  end

  defp package do
    [
      name: "keen_microsoft_graphapi",
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url},
      files: ~w(lib .formatter.exs mix.exs README.md LICENSE CHANGELOG.md)
    ]
  end

  defp docs do
    [
      main: "readme",
      source_ref: "v#{@version}",
      extras: [
        "README.md",
        "CHANGELOG.md",
        "LICENSE"
      ],
      groups_for_modules: [
        "Resources": [
          GraphApi.Users,
          GraphApi.Groups,
          GraphApi.Mail,
          GraphApi.Calendar,
          GraphApi.Files,
          GraphApi.Subscriptions
        ],
        "Query & Pagination": [
          GraphApi.OData,
          GraphApi.OData.Filter,
          GraphApi.Pagination,
          GraphApi.Delta,
          GraphApi.Batch
        ],
        "Client & Config": [
          GraphApi.Client,
          GraphApi.Config,
          GraphApi.Auth,
          GraphApi.Auth.Delegated,
          GraphApi.TokenStore
        ],
        "Schema (v1.0)": ~r/GraphApi\.Schema\.(?!Beta|Generator)/,
        "Schema (Beta)": ~r/GraphApi\.Schema\.Beta\./,
        "Schema Generator": ~r/GraphApi\.Schema\.Generator\./,
        "Middleware": ~r/GraphApi\.Middleware\./,
        "Errors & Helpers": [
          GraphApi.Error,
          GraphApi.Response,
          GraphApi.Resource,
          GraphApi.View,
          GraphApi.Webhook
        ]
      ]
    ]
  end

  defp aliases do
    [
      quality: ["format --check-formatted", "credo --strict", "dialyzer"]
    ]
  end
end
