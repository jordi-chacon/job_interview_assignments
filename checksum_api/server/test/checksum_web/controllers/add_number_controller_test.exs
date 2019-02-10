defmodule ChecksumWeb.AddNumberControllerTest do
  use ChecksumWeb.ConnCase
  alias Checksum.NumbersServer

  test "missing number causes 400", %{conn: conn} do
    response =
      conn
      |> post(uri(conn), %{})
      |> json_response(400)

    expected = %{
      "errors" => [
        %{"field" => "number", "reason" => "must be present"},
        %{"field" => "number", "reason" => "must have the correct format"},
        %{"field" => "number", "reason" => "must be a string"}
      ]
    }

    assert response == expected
  end

  test "negative number causes 400", %{conn: conn} do
    response =
      conn
      |> post(uri(conn), %{number: "-2"})
      |> json_response(400)

    expected = %{
      "errors" => [
        %{"field" => "number", "reason" => "must have the correct format"}
      ]
    }

    assert response == expected
  end

  test "float number causes 400", %{conn: conn} do
    response =
      conn
      |> post(uri(conn), %{number: "2.2"})
      |> json_response(400)

    expected = %{
      "errors" => [
        %{"field" => "number", "reason" => "must have the correct format"}
      ]
    }

    assert response == expected
  end

  test "valid number gets added to NumbersServer", %{conn: conn} do
    response =
      conn
      |> post(uri(conn), %{number: "123"})
      |> json_response(200)

    assert response == %{}
    assert NumbersServer.checksum() == 6
  end

  test "invalid Accept header returns 406", %{conn: conn} do
    response =
      assert_error_sent 406, fn ->
        conn
        |> put_req_header("accept", "application/json")
        |> post(uri(conn), %{})
      end

    assert response |> elem(2) |> Jason.decode!() ==
             %{"errors" => %{"detail" => "Not Acceptable"}}
  end

  test "response contains valid Content-Type header", %{conn: conn} do
    header_value =
      post(conn, uri(conn), %{number: "123"})
      |> Map.get(:resp_headers)
      |> Enum.find(&(elem(&1, 0) == "content-type"))
      |> elem(1)

    assert header_value == "application/vnd.checksum.v1+json"
  end

  defp uri(conn) do
    Routes.add_number_path(conn, :add)
  end
end
