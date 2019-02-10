defmodule ChecksumWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :checksum

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    plug(Phoenix.CodeReloader)
  end

  plug(Plug.RequestId)
  plug(Plug.Logger)

  plug(Plug.Parsers,
    parsers: [:json],
    json_decoder: Phoenix.json_library()
  )

  plug(ChecksumWeb.Router)
end
