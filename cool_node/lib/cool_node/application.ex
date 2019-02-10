defmodule CoolNode.Application do
  use Application

  def start(_type, _args) do
    if Mix.env() == :prod do
      :net_adm.world()
    end

    children = [
      Supervisor.Spec.worker(CoolNode.Server, [])
    ]

    opts = [strategy: :one_for_one, name: CoolNode.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
