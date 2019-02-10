defmodule ChecksumWeb.GetChecksumControllerTest do
  use ChecksumWeb.ConnCase
  alias Checksum.NumbersServer

  setup do
    NumbersServer.clear()
    NumbersServer.add("123")

    on_exit(fn ->
      NumbersServer.clear()
      :meck.unload()
    end)
  end

  test "valid checksum in response", %{conn: conn} do
    response =
      conn
      |> get(uri(conn))
      |> json_response(200)

    assert response == %{"checksum" => 6}
  end

  test "NumbersServer timeout causes 500 {error: timeout}", %{conn: conn} do
    :meck.new(NumbersServer, [:passthrough])

    :meck.expect(
      NumbersServer,
      :handle_call,
      fn _, _, state ->
        :timer.sleep(100)
        {:reply, :ok, state}
      end
    )

    response =
      conn
      |> get(uri(conn))
      |> json_response(500)

    assert response == %{"error" => "timeout"}
  end

  defp uri(conn) do
    Routes.get_checksum_path(conn, :get)
  end
end
