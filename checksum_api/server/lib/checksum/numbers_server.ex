defmodule Checksum.NumbersServer do
  use GenServer

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def add(number) do
    GenServer.call(__MODULE__, {:add, number})
  end

  # Timeout after 15ms.
  # When timeout happens, we want to return a controlled error back to the
  # client so we have to catch the timeout error.
  # When a timeout occurs, the GenServer will anyway send a message to the
  # caller when the checksum has been calculated. This will clutter the caller
  # mailbox. Therefore we flush the mailbox from such messages here, although
  # we could choose to flush the mailbox somewhere else in the code.
  def checksum() do
    flush_mailbox()

    try do
      GenServer.call(__MODULE__, :checksum, 15)
    catch
      :exit, {:timeout, _} ->
        :timeout
    end
  end

  def clear() do
    GenServer.call(__MODULE__, :clear)
  end

  ## Callbacks

  @impl true
  def init(_) do
    {:ok, empty_state()}
  end

  @impl true
  def handle_call({:add, number}, _from, state) do
    new_state = add_number_to_state(state, number)
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call(:checksum, _from, state) do
    {:reply, checksum(state), state}
  end

  @impl true
  def handle_call(:clear, _from, _state) do
    {:reply, :ok, empty_state()}
  end

  defp empty_state() do
    %{odd: [], even: [], next: :odd}
  end

  defp add_number_to_state(state, "") do
    state
  end

  defp add_number_to_state(state, <<digit::binary-size(1)>> <> number) do
    state
    |> Map.update!(state.next, &[String.to_integer(digit) | &1])
    |> Map.update!(:next, &next/1)
    |> add_number_to_state(number)
  end

  defp next(:odd), do: :even
  defp next(:even), do: :odd

  defp checksum(state) do
    odd_sum = Enum.sum(state.odd)
    even_sum = Enum.sum(state.even)

    odd_sum
    |> Kernel.*(3)
    |> Kernel.+(even_sum)
    |> rem(10)
    |> case do
      0 -> 0
      n -> 10 - n
    end
  end

  defp flush_mailbox do
    receive do
      {ref, n} when is_reference(ref) and is_number(n) ->
        flush_mailbox()
    after
      0 ->
        :ok
    end
  end
end
