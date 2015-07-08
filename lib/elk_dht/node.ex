defmodule ElkDHT.Node do
  use GenServer
  require Logger
  alias ElkDHT.Utils
  alias ElkDHT.Node.Transaction

  def start_link(host, port, node_id) do
    GenServer.start_link __MODULE__, [host, port, node_id], [name: :"#{Hexate.encode(node_id)}"]
  end

  def create(host, port) do
    node_id = Utils.random_node_id
    create(host, port, node_id)
  end

  def create(host, port, node_id) do
    case ElkDHT.Supervisor.start_child(host, port, node_id) do
      {:ok, pid} -> {:ok, pid}
      other -> {:error, other}
    end
  end

  def find_node(node_pid) do
    send_message node_pid, :find_node
  end

  def node_id(pid) do
    GenServer.call pid, :get_node_id
  end

  def socket(pid) do
    GenServer.call pid, :get_socket
  end

  defp send_message(pid, type) do
    trans_id = GenServer.call pid, {:add_trans, type}
    GenServer.cast pid, {:send_message, type, trans_id}
  end

  defp build_message(id, :find_node) do
    %{ "y" => "q",
       "q" => "find_node",
       "a" => %{ "id" => id,
                 "target" => id}}
  end

  defp add_trans(pid, type) do
    GenServer.call pid, {:add_trans, type}
  end

  def init([host, port, node_id]) do
    Logger.debug fn -> "New node #{Hexate.encode(node_id)} #{host}:#{port}" end
    {:ok, socket} = :gen_udp.open 0
    Logger.debug fn -> {:ok, port} = :inet.port(socket); "Listening to port #{port}" end
    {:ok, %{id: node_id, host: to_char_list(host), port: port, socket: socket, transactions: HashDict.new, trans_refs: HashDict.new}}
  end

  def terminate(_reason, _state = %{id: id, host: host, port: port}) do
    Logger.debug fn -> "Tearing down node #{Hexate.encode(id)} #{host}:#{port}" end
    :ok
  end

  def handle_cast({:send_message, type, trans_id}, state = %{id: id, host: host, port: port, socket: socket}) do
    message = build_message(id, type)
    encoded = message
    |> Map.put("v", Utils.get_version)
    |> Map.put("t", trans_id)
    |> Bencode.encode!
    :gen_udp.send socket, to_char_list(host), port, [encoded]
    Logger.info "Message sent for transaction: #{Hexate.encode(trans_id)}"
    {:noreply, state}
  end

  def handle_call({:add_trans, type}, _from, state = %{transactions: transactions, trans_refs: trans_refs}) do
    trans_id = Utils.random_trans_id
    {:ok, pid} = Transaction.start_link(trans_id, type)
    ref = Process.monitor pid
    transactions = Dict.put transactions, trans_id, pid
    trans_refs = Dict.put trans_refs, ref, trans_id
    {:reply, trans_id, %{state | transactions: transactions, trans_refs: trans_refs}}
  end

  def handle_call(:get_node_id, _from, state = %{id: id}) do
    {:reply, id, state}
  end

  def handle_call(:get_socket, _from, state = %{socket: socket}) do
    {:reply, socket, state}
  end

  def handle_call({:get_trans, trans_id}, _from, state) do
    {:reply, Dict.fetch!(state.transactions, trans_id), state}
  end

  def handle_info({:udp, socket, {a, b, c, d}, port, data}, state = %{port: port, socket: socket}) do
    Logger.debug "Message received from #{a}.#{b}.#{c}.#{d}:#{port}"
    File.write!("received", data)
    decoded = data
    |> Enum.reduce("", fn(x, acc) -> acc <> <<x>> end)
    |> Bencode.decode!
    trans_pid = Dict.fetch! state.transactions, Map.get(decoded, "t")
    Transaction.process_message trans_pid, decoded
    {:noreply, state}
  end

  def handle_info({:DOWN, ref, :process, _pid, reason}, state = %{transactions: transactions, trans_refs: trans_refs}) do
    {trans, refs} = Dict.pop trans_refs, ref
    transactions = Dict.delete transactions, trans
    Logger.debug "Transaction #{Hexate.encode(trans)} down."
    {:noreply, %{state | transactions: transactions, trans_refs: refs}}
  end

end
