defmodule ExDHT.Node do
  use GenServer
  require Logger
  alias ExDHT.Utils
  alias ExDHT.Node.Transaction
  alias ExDHT.Node.Pinger
  alias ExDHT.Node.Suicider
  defmodule State, do: defstruct id: nil, host: nil, port: nil, socket: nil, transactions: nil, trans_refs: nil, suicider: nil

  @ping_interval 10000
  @life_count 30
  
  def start_link(host, port, node_id) do
    GenServer.start_link __MODULE__, [host, port, node_id], [name: :"#{Hexate.encode(node_id)}"]
  end

  def create(host, port) do
    node_id = Utils.random_node_id
    create(host, port, node_id)
  end

  def create(host, port, node_id) do
    case ExDHT.Supervisor.start_child(host, port, node_id) do
      {:ok, pid} -> {:ok, pid}
      other -> {:error, other}
    end
  end

  def find_node(node_pid) do
    send_message node_pid, :find_node
  end

  def ping(node_pid) do
    send_message node_pid, :ping
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

  defp build_message(id, :ping) do
    %{ "y" => "q",
       "q" => "ping",
       "a" => %{ "id" => id }}
  end

  defp add_trans(pid, type) do
    GenServer.call pid, {:add_trans, type}
  end

  def init([host, port, node_id]) do
    Logger.debug fn -> "New node #{Hexate.encode(node_id)} #{host}:#{port}" end
    {:ok, socket} = :gen_udp.open 0
    Logger.debug fn -> {:ok, port} = :inet.port(socket); "Listening to port #{port}" end
    {:ok, suicider} = Suicider.start_link @ping_interval, @life_count
    {:ok, _pinger} = Pinger.start_link self, @ping_interval
    {:ok, %State{id: node_id, host: to_char_list(host), port: port, socket: socket, transactions: HashDict.new, trans_refs: HashDict.new, suicider: suicider}}
  end

  def terminate(_reason, state) do
    Logger.debug fn -> "Tearing down node #{Hexate.encode(state.id)} #{state.host}:#{state.port}" end
    :ok
  end

  def handle_cast({:send_message, type, trans_id}, state) do
    message = build_message(state.id, type)
    encoded = message
    |> Map.put("v", Utils.get_version)
    |> Map.put("t", trans_id)
    |> Bencode.encode!
    :gen_udp.send state.socket, state.host, state.port, [encoded]
    Logger.debug "Message sent for transaction: #{Hexate.encode(trans_id)}"
    {:noreply, state}
  end

  def handle_call({:add_trans, type}, _from, state) do
    trans_id = Utils.random_trans_id
    {:ok, pid} = Transaction.start_link(trans_id, type, self)
    ref = Process.monitor pid
    transactions = Dict.put state.transactions, trans_id, pid
    trans_refs = Dict.put state.trans_refs, ref, trans_id
    {:reply, trans_id, %{state | transactions: transactions, trans_refs: trans_refs}}
  end

  def handle_call(:get_node_id, _from, %State{id: id} = state) do
    {:reply, id, state}
  end

  def handle_call(:get_socket, _from, %State{socket: socket} = state) do
    {:reply, socket, state}
  end

  def handle_call({:get_trans, trans_id}, _from, state) do
    {:reply, Dict.fetch!(state.transactions, trans_id), state}
  end

  def handle_info({:udp, socket, {a, b, c, d}, port, data}, %State{port: port, socket: socket, suicider: suicider} = state) do
    Logger.debug "Message received from #{a}.#{b}.#{c}.#{d}:#{port}"
    Suicider.revive suicider
    decoded = data
    |> Enum.reduce("", fn(x, acc) -> acc <> <<x>> end)
    |> Bencode.decode!
    trans_pid = Dict.fetch! state.transactions, Map.get(decoded, "t")
    Transaction.process_message trans_pid, decoded
    {:noreply, state}
  end

  def handle_info({:DOWN, ref, :process, suicider, :normal}, %State{suicider: suicider} = state) do
    {trans, refs} = Dict.pop state.trans_refs, ref
    transactions = Dict.delete state.transactions, trans
    Logger.debug "Node #{Hexate.encode(state.id)} does not respond, removing it..."
    {:stop, :normal, %{state | transactions: transactions, trans_refs: refs}}
  end
  

  def handle_info({:DOWN, ref, :process, _pid, _reason}, state) do
    {trans, refs} = Dict.pop state.trans_refs, ref
    transactions = Dict.delete state.transactions, trans
    Logger.debug "Transaction #{Hexate.encode(trans)} down."
    {:noreply, %{state | transactions: transactions, trans_refs: refs}}
  end

end
