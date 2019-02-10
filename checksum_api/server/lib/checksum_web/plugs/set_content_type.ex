defmodule ChecksumWeb.Plugs.SetContentType do
  import Plug.Conn

  def init(options), do: options

  def call(conn, _opts) do
    conn
    |> put_resp_header("content-type", conn.private.raw_version)
  end
end
