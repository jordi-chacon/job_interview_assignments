defmodule CoolNodeTest do
  use ExUnit.Case
  alias CoolNode.Server

  # For ease of testing, this test suite runs multiple CoolNode.Server
  # instances as local processes instead of as processes in different nodes.
  # Despite of this simplification we are able to test the logic that handles
  # leader monitoring and election.

  setup do
    kill_all_servers()

    on_exit(fn ->
      kill_all_servers()
    end)
  end

  test "one node in cluster" do
    start_server(:s1)
    wait_for_network_to_stabilize()
    assert get_leader_in_server(:s1) == :me
  end

  test "one node joins cluster, then another one" do
    start_server(:s1)
    :timer.sleep(100)
    start_server(:s2)
    wait_for_network_to_stabilize()
    assert get_leader_in_server(:s2) == :me
    assert get_leader_in_server(:s1) == :s2
  end

  test "two nodes join the cluster 'simultaneously'" do
    start_server(:s1)
    start_server(:s2)
    wait_for_network_to_stabilize()
    assert get_leader_in_server(:s2) == :me
    assert get_leader_in_server(:s1) == :s2
  end

  test "two nodes in cluster, then kill leader" do
    start_server(:s1)
    start_server(:s2)
    wait_for_network_to_stabilize()
    assert get_leader_in_server(:s2) == :me
    assert get_leader_in_server(:s1) == :s2

    kill_server(:s2)
    wait_for_network_to_stabilize([:s2])
    assert get_leader_in_server(:s1) == :me
  end

  test "two nodes in cluster, then add another one with smaller ID" do
    start_server(:s2)
    start_server(:s3)
    wait_for_network_to_stabilize()

    start_server(:s1)
    wait_for_network_to_stabilize()
    assert_leader(1..3)
  end

  test "two nodes in cluster, then add another one with biggest ID" do
    start_server(:s2)
    start_server(:s1)
    wait_for_network_to_stabilize()

    start_server(:s3)
    wait_for_network_to_stabilize()
    assert_leader(1..3)
  end

  test "three nodes in cluster, kill leader, then kill new leader" do
    start_server(:s2)
    start_server(:s3)
    start_server(:s1)
    wait_for_network_to_stabilize()
    assert_leader(1..3)

    kill_server(:s3)
    wait_for_network_to_stabilize([:s3])
    assert_leader(1..2)

    kill_server(:s2)
    wait_for_network_to_stabilize([:s2])
    assert get_leader_in_server(:s1) == :me
  end

  test "10 nodes in cluster" do
    start_server(:s2)
    start_server(:s3)
    start_server(:s1)
    start_server(:s4)
    wait_for_network_to_stabilize()
    assert_leader(1..4)

    start_server(:s7)
    start_server(:s5)
    start_server(:s8)
    start_server(:s6)
    start_server(:s9)
    start_server(:s0)
    wait_for_network_to_stabilize()
    assert_leader(0..9)

    kill_server(:s3)
    kill_server(:s4)
    wait_for_network_to_stabilize([:s3, :s4])
    assert_leader([0, 1, 2, 5, 6, 7, 8, 9])

    start_server(:s3)
    start_server(:s4)
    wait_for_network_to_stabilize()
    assert_leader(0..9)

    kill_server(:s9)
    kill_server(:s8)
    kill_server(:s7)
    kill_server(:s6)
    wait_for_network_to_stabilize([:s9, :s8, :s7, :s6])
    assert_leader(0..5)
  end

  defp start_server(name) do
    name = add_prefix_to_server_name(name)
    GenServer.start(Server, config(), name: name)
  end

  defp config do
    self = self()

    %{
      log: fn type, args ->
        Kernel.send(self, {get_process_registered_name(), {type, args}})
      end,
      node_list: fn ->
        Enum.filter(server_list(), &(&1 != get_process_registered_name()))
      end,
      self: &get_process_registered_name/0,
      send: fn recipient, sender, message ->
        try do
          Kernel.send(recipient, {sender, message})
        rescue
          ArgumentError -> :ok
        end
      end,
      time_interval: 100
    }
  end

  defp get_process_registered_name do
    Process.info(self(), :registered_name) |> elem(1)
  end

  defp assert_leader(%Range{} = number_ids) do
    number_ids
    |> Enum.map(& &1)
    |> assert_leader
  end

  defp assert_leader([n | _] = number_ids) when is_integer(n) do
    number_ids
    |> Enum.map(&("s#{&1}" |> String.to_atom()))
    |> assert_leader
  end

  defp assert_leader(server_names) do
    expected_leader =
      server_names
      |> Enum.sort()
      |> Enum.reverse()
      |> hd

    Enum.each(
      server_names,
      fn name ->
        leader = get_leader_in_server(name)

        error_msg = fn expected, actual ->
          "Unexpected leader in server #{inspect(name)}.\n" <>
            "Expected #{inspect(expected)}\n" <>
            "Got #{inspect(actual)}"
        end

        case name == expected_leader do
          true ->
            assert(leader == :me, error_msg.(:me, leader))

          false ->
            assert(
              leader == expected_leader,
              error_msg.(expected_leader, leader)
            )
        end
      end
    )
  end

  defp get_leader_in_server(name) do
    case GenServer.call(add_prefix_to_server_name(name), :get_leader) do
      :me -> :me
      leader_name -> remove_prefix_from_server_name(leader_name)
    end
  end

  defp kill_all_servers do
    Enum.each(
      server_list(),
      fn name ->
        try do
          kill_server(name)
        rescue
          ArgumentError ->
            :ok
        end
      end
    )

    :timer.sleep(100)
  end

  defp kill_server(name) do
    case has_prefix?(name) do
      true -> name
      false -> add_prefix_to_server_name(name)
    end
    |> Process.whereis()
    |> Process.exit(:kill)
  end

  defp add_prefix_to_server_name(server_name) do
    "coolnodetest_#{server_name}" |> String.to_atom()
  end

  defp remove_prefix_from_server_name(name) do
    name
    |> Atom.to_string()
    |> String.split("_")
    |> Enum.at(1)
    |> String.to_atom()
  end

  defp has_prefix?(name) do
    name |> Atom.to_string() |> String.starts_with?("coolnodetest")
  end

  defp server_list do
    Process.registered()
    |> Enum.filter(fn name ->
      case is_atom(name) do
        true ->
          name |> Atom.to_string() |> String.starts_with?("coolnodetest")

        false ->
          false
      end
    end)
  end

  defp wait_for_network_to_stabilize(ignore_nodes \\ [], messages \\ %{}) do
    receive do
      {sender, message} ->
        case Enum.member?(
               ignore_nodes,
               remove_prefix_from_server_name(sender)
             ) do
          true ->
            wait_for_network_to_stabilize(ignore_nodes, messages)

          false ->
            sender = remove_prefix_from_server_name(sender)
            messages = Map.update(messages, sender, [message], &[message | &1])

            case is_network_stable?(messages) do
              true -> :ok
              false -> wait_for_network_to_stabilize(ignore_nodes, messages)
            end
        end
    after
      1000 ->
        :ok
    end
  end

  defp is_network_stable?(messages) do
    Enum.all?(
      messages,
      fn {_node, messages_from_node} ->
        messages_from_node
        |> Enum.take_while(&is_leader_monitoring_message?/1)
        |> length
        |> Kernel.>(16)
      end
    )
  end

  defp is_leader_monitoring_message?(message) do
    case message do
      {:task_received, %{task: {:ping_leader, _}}} -> true
      {:task_received, %{task: {:monitor_leader, _}}} -> true
      {:message_sent, %{message: :PING}} -> true
      {:message_sent, %{message: :PONG}} -> true
      {:message_received, %{message: :PING}} -> true
      {:message_received, %{message: :PONG}} -> true
      _ -> false
    end
  end
end
