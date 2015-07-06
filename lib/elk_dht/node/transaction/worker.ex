defmodule ElkDHT.Node.Transaction.Worker do
  use GenServer
  require Logger

  def start_link(host, port, node_pid) do
    GenServer.start_link __MODULE__, [host, port, node_pid]
  end

  def send_message(pid, message) when is_map(message) do
    GenServer.cast pid, {:send_message, message}
  end

  def init([host, port, node_pid]) do
    trans_id = ElkDHT.Utils.random_trans_id
    Logger.debug "Transaction #{Hexate.encode(trans_id)} initialized"
    {:ok, %{id: trans_id, host: host, port: port, node: node_pid}}
  end

  def handle_cast({:send_message, message}, state = %{id: trans_id, host: host, port: port, node: node_pid}) when is_map(message) do
    Logger.debug "Sending message for transaction: #{Hexate.encode(trans_id)}"
    encoded = message
    |> Map.put("v", ElkDHT.Utils.get_version)
    |> Map.put("t", trans_id)
    |> Bencode.encode!
    ElkDHT.Node.Worker.socket(node_pid)
    |> :gen_udp.send(to_char_list(host), port, [encoded])
    {:noreply, state}
  end

end
