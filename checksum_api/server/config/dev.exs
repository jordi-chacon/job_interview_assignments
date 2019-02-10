use Mix.Config

config :checksum, ChecksumWeb.Endpoint,
  code_reloader: true,
  check_origin: false,
  watchers: []

config :phoenix, :stacktrace_depth, 20

config :phoenix, :plug_init_mode, :runtime
