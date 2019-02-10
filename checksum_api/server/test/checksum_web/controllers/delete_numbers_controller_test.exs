defmodule ChecksumWeb.DeleteNumbersControllerTest do
  use ChecksumWeb.ConnCase
  alias Checksum.NumbersServer

  setup do
    NumbersServer.clear()
    NumbersServer.add("123")
    assert NumbersServer.checksum() == 6

    on_exit(fn ->
      NumbersServer.clear()
    end)
  end

  test "NumbersServer state gets cleared", %{conn: conn} do
    response =
      conn
      |> delete(uri(conn))
      |> json_response(200)

    assert response == %{}
    assert NumbersServer.checksum() == 0
  end

  defp uri(conn) do
    Routes.delete_numbers_path(conn, :delete)
  end
end
