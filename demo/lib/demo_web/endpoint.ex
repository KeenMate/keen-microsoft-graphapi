defmodule DemoWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :demo

  @session_options [
    store: :cookie,
    key: "_demo_key",
    signing_salt: "graph_explorer",
    same_site: "Lax"
  ]

  socket "/live", Phoenix.LiveView.Socket,
    websocket: [connect_info: [session: @session_options]]

  plug Plug.Static, at: "/assets/phoenix", from: {:phoenix, "priv/static"}
  plug Plug.Static, at: "/assets/phoenix_live_view", from: {:phoenix_live_view, "priv/static"}

  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
  end

  plug Plug.RequestId
  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options
  plug DemoWeb.Router
end
