defmodule GraphApi.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      GraphApi.TokenStore
    ]

    opts = [strategy: :one_for_one, name: GraphApi.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
