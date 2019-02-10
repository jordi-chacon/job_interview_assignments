defmodule ChecksumWeb.DeleteNumbersController do
  use ChecksumWeb, :controller
  alias Checksum.NumbersServer

  def delete(conn, _params) do
    NumbersServer.clear()

    conn
    |> put_status(200)
    |> json(%{})
  end
end
