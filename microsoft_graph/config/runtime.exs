import Config

if config_env() == :prod do
  config :microsoft_graph, :config,
    tenant_id: System.fetch_env!("AZURE_TENANT_ID"),
    client_id: System.fetch_env!("AZURE_CLIENT_ID"),
    client_secret: System.fetch_env!("AZURE_CLIENT_SECRET")
end
