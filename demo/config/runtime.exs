import Config

if config_env() in [:dev, :prod] do
  tenant_id = System.get_env("AZURE_TENANT_ID")
  client_id = System.get_env("AZURE_CLIENT_ID")
  client_secret = System.get_env("AZURE_CLIENT_SECRET")

  if tenant_id && client_id && client_secret do
    config :microsoft_graph, :config,
      tenant_id: tenant_id,
      client_id: client_id,
      client_secret: client_secret
  end
end
