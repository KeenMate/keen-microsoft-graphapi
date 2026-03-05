defmodule DemoWeb.Router do
  use Phoenix.Router

  import Phoenix.LiveView.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {DemoWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  scope "/", DemoWeb do
    pipe_through :browser

    live "/", ExplorerLive

    get "/auth/login", AuthController, :login
    get "/auth/callback", AuthController, :callback
    get "/auth/logout", AuthController, :logout
  end
end
