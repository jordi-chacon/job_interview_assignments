use Mix.Config

config :checksum,
  namespace: Checksum

config :checksum, ChecksumWeb.Endpoint,
  url: [host: "localhost"],
  http: [port: 4000],
  secret_key_base:
    "BcfR1LEdGKbDK3a3C+Kl+EgLEtayOy4f3/ML2mna9oCRWFfQw/FiqiMdzqgmF4YM",
  render_errors: [view: ChecksumWeb.ErrorView, accepts: ~w(json)]

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :json_library, Jason

config :mime, :types, %{
  "application/vnd.checksum.v1+json" => [:v1]
}

import_config "#{Mix.env()}.exs"
