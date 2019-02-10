defmodule ChecksumWeb.AddNumberController do
  use ChecksumWeb, :controller
  alias Checksum.NumbersServer

  def add(conn, params) do
    case validate_params(params) do
      :ok ->
        NumbersServer.add(params["number"])

        conn
        |> put_status(200)
        |> json(%{})

      {:errors, errors} ->
        conn
        |> put_status(400)
        |> json(%{errors: errors})
    end
  end

  defp validate_params(params) do
    errors =
      Vex.errors(
        params,
        %{
          "number" => [
            presence: true,
            format: ~r/^[0-9]+$/,
            by: &if(is_binary(&1), do: :ok, else: {:error, "must be a string"})
          ]
        }
      )
      |> Enum.map(fn {:error, field, _, reason} ->
        %{field: field, reason: reason}
      end)

    case errors do
      [] -> :ok
      _ -> {:errors, errors}
    end
  end
end
