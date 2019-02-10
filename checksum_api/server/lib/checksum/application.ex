defmodule Checksum.Application do
  use Application

  def start(_type, _args) do
    children = [
      ChecksumWeb.Endpoint,
      Supervisor.Spec.worker(Checksum.NumbersServer, [])
    ]

    opts = [strategy: :one_for_one, name: Checksum.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def config_change(changed, _new, removed) do
    ChecksumWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
