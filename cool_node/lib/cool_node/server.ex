defmodule CoolNode.Server do
  use GenServer

  def start_link() do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  # CALLBACKS #################################################################

  @impl true
  def init(config) do
    default_config = %{
      log: &log/2,
      node_list: &Node.list/0,
      self: &Node.self/0,
      send: fn recipient, sender, message ->
        Kernel.send({__MODULE__, recipient}, {sender, message})
      end,
      time_interval: 1000
    }

    config = Map.merge(default_config, config)

    initial_state = %{
      config: config,
      election_id: nil,
      leader: nil,
      received_finethanks: 0,
      unacked_pings: 0
    }

    {:ok, start_leader_election(initial_state)}
  end

  # Used in testing
  @impl true
  def handle_call(:get_leader, _from, state) do
    {:reply, state.leader, state}
  end

  @impl true
  def handle_info(message, state) do
    log_handle_info(message, state)

    case message do
      {sender, {:ALIVE?, election_id}} ->
        handle_alive_message(state, sender, election_id)

      {sender, :IAMTHEKING} ->
        handle_iamtheking_message(state, sender)

      {sender, :PING} ->
        handle_ping_message(state, sender)

      {sender, :PONG} ->
        handle_pong_message(state, sender)

      {_sender, {:FINETHANKS, election_id}} ->
        handle_finethanks_message(state, election_id)

      {:task, {:ping_leader, leader_to_ping}} ->
        do_task_ping_leader(state, leader_to_ping)

      {:task, {:monitor_leader, leader_to_monitor}} ->
        do_task_monitor_leader(state, leader_to_monitor)

      {:task, {:monitor_election, election_id}} ->
        do_task_monitor_election(state, election_id)

      {:task, {:ensure_leader_elected, election_id}} ->
        do_task_ensure_leader_elected(state, election_id)
    end
  end

  # HANDLE MESSAGES FROM OTHER NODES ##########################################

  defp handle_alive_message(%{config: config} = state, sender, election_id) do
    send_message(sender, {:FINETHANKS, election_id}, config)

    case nodes_with_greater_id(config) do
      [] ->
        {:noreply, become_king(state)}

      [_ | _] ->
        {:noreply, start_leader_election(state)}
    end
  end

  defp handle_iamtheking_message(state, sender) do
    case state.leader == :me or sender < state.config.self.() do
      true ->
        {:noreply, start_leader_election(state)}

      false ->
        case sender == state.leader do
          true ->
            {:noreply, state}

          false ->
            state =
              state
              |> Map.put(:leader, sender)
              |> Map.put(:unacked_pings, 0)
              |> Map.put(:election_id, nil)

            schedule_task({:ping_leader, state.leader}, state.config, 0)

            {:noreply, state}
        end
    end
  end

  defp handle_ping_message(state, sender) do
    send_message(sender, :PONG, state.config)
    {:noreply, state}
  end

  defp handle_pong_message(state, sender) do
    case sender == state.leader do
      true ->
        {:noreply, Map.update!(state, :unacked_pings, &(&1 - 1))}

      false ->
        {:noreply, state}
    end
  end

  defp handle_finethanks_message(state, election_id) do
    case election_id == state.election_id and state.received_finethanks == 0 do
      true ->
        schedule_task({:ensure_leader_elected, election_id}, state.config)
        {:noreply, Map.update!(state, :received_finethanks, &(&1 + 1))}

      false ->
        {:noreply, state}
    end
  end

  # DO NODE TASKS #############################################################

  defp do_task_ping_leader(state, leader_to_ping) do
    case state.leader == leader_to_ping do
      true ->
        send_message(state.leader, :PING, state.config)
        schedule_task({:ping_leader, state.leader}, state.config)
        schedule_task({:monitor_leader, state.leader}, state.config, 4)
        {:noreply, Map.update!(state, :unacked_pings, &(&1 + 1))}

      false ->
        {:noreply, state}
    end
  end

  defp do_task_monitor_leader(state, leader_to_monitor) do
    case state.leader == leader_to_monitor and state.unacked_pings >= 3 do
      true ->
        {:noreply, start_leader_election(state)}

      false ->
        {:noreply, state}
    end
  end

  defp do_task_monitor_election(state, election_id) do
    case election_id != state.election_id or state.received_finethanks > 0 do
      true ->
        {:noreply, state}

      false ->
        {:noreply, become_king(state)}
    end
  end

  defp do_task_ensure_leader_elected(state, election_id) do
    case election_id == state.election_id and state.leader == nil do
      true ->
        {:noreply, start_leader_election(state)}

      false ->
        {:noreply, state}
    end
  end

  # CORE FUNCTIONS ############################################################

  defp start_leader_election(%{config: config} = state) do
    election_id = ms_now()
    log(:start_election, %{id: election_id}, config)

    send_message(nodes_with_greater_id(config), {:ALIVE?, election_id}, config)
    schedule_task({:monitor_election, election_id}, config)

    state
    |> Map.put(:leader, nil)
    |> Map.put(:received_finethanks, 0)
    |> Map.put(:election_id, election_id)
  end

  defp become_king(%{config: config} = state) do
    log(:become_king, %{}, state.config)
    send_message(config.node_list.(), :IAMTHEKING, config)
    Map.put(state, :leader, :me)
  end

  # UTILS #####################################################################

  defp nodes_with_greater_id(config) do
    self_id = config.self.()

    config.node_list.()
    |> Enum.filter(&(&1 > self_id))
  end

  defp send_message(nodes, message, config) when is_list(nodes) do
    Enum.each(nodes, &send_message(&1, message, config))
  end

  defp send_message(node, message, config) do
    config.send.(node, config.self.(), message)
    log(:message_sent, %{recipient: node, message: message}, config)
  end

  defp schedule_task(task, config, interval_multiplier \\ 1) do
    Process.send_after(
      self(),
      {:task, task},
      config.time_interval * interval_multiplier
    )
  end

  defp log_handle_info(message, state) do
    case message do
      {:task, task} ->
        log(:task_received, %{task: task}, state.config)

      {sender, content} ->
        log(
          :message_received,
          %{sender: sender, message: content},
          state.config
        )
    end
  end

  defp log(type, args, config) do
    config.log.(type, args)
  end

  defp log(type, args) do
    stringified_args =
      args
      |> Enum.map(fn {k, v} -> ". #{k}: #{inspect(v)}" end)
      |> Enum.join("")

    File.write(
      "/tmp/cool_node.#{Node.self()}.log",
      "[#{Time.utc_now()}] #{type}#{stringified_args}\n",
      [:append]
    )
  end

  defp ms_now do
    :os.system_time(:millisecond)
  end
end
