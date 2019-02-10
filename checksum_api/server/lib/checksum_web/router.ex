defmodule ChecksumWeb.Router do
  use ChecksumWeb, :router

  pipeline :pre_processing do
    plug Versionary.Plug.VerifyHeader, accepts: [:v1]

    plug Versionary.Plug.EnsureVersion,
      handler: Versionary.Plug.PhoenixErrorHandler

    plug ChecksumWeb.Plugs.SetContentType
  end

  scope "/", ChecksumWeb do
    pipe_through(:pre_processing)
    get("/numbers/checksum", GetChecksumController, :get)
    post("/numbers", AddNumberController, :add)
    delete("/numbers", DeleteNumbersController, :delete)
  end
end
