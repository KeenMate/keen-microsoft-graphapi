import Config

config :demo, DemoWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [
    formats: [html: DemoWeb.ErrorHTML],
    layout: false
  ],
  pubsub_server: Demo.PubSub,
  live_view: [signing_salt: "graph_explorer_dev"]

config :phoenix, :json_library, Jason

import_config "#{config_env()}.exs"
