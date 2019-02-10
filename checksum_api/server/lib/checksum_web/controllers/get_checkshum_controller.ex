defmodule ChecksumWeb.GetChecksumController do
  use ChecksumWeb, :controller
  alias Checksum.NumbersServer

  def get(conn, _params) do
    case NumbersServer.checksum() do
      :timeout ->
        conn
        |> put_status(500)
        |> json(%{error: :timeout})

      checksum ->
        conn
        |> put_status(200)
        |> json(%{checksum: checksum})
    end
  end
end
