defmodule MicrosoftGraph.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      MicrosoftGraph.TokenStore
    ]

    opts = [strategy: :one_for_one, name: MicrosoftGraph.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
