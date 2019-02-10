use Mix.Config

config :checksum, ChecksumWeb.Endpoint,
  http: [port: {:system, "PORT"}],
  url: [host: "localhost", port: {:system, "PORT"}],
  server: true

config :logger, level: :info
