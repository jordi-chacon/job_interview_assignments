defmodule ChecksumWeb.ConnCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      use Phoenix.ConnTest
      alias ChecksumWeb.Router.Helpers, as: Routes

      @endpoint ChecksumWeb.Endpoint
    end
  end

  setup _tags do
    Checksum.NumbersServer.clear()

    on_exit(fn ->
      Checksum.NumbersServer.clear()
    end)

    conn =
      Phoenix.ConnTest.build_conn()
      |> Plug.Conn.put_req_header("accept", "application/vnd.checksum.v1+json")

    {:ok, %{conn: conn}}
  end
end
