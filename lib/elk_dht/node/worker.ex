defmodule ElkDHT.Node.Worker do
  use GenServer
  require Logger
  alias ElkDHT.Utils
  alias ElkDHT.Node.Transaction
  @trans_timeout 5000

  def start_link(host, port) do
    GenServer.start_link __MODULE__, [host, port]
  end

  def node_id(pid) do
    GenServer.call pid, :get_node_id
  end

  def socket(pid) do
    GenServer.call pid, :get_socket
  end

  def message(pid, :find_node) do
    id = node_id(pid)
    %{ "y" => "q",
       "q" => "find_node",
       "a" => %{ "id" => id,
                 "target" => id}}
  end

  def init([host, port]) do
    node_id = Utils.random_node_id
    Logger.debug fn -> "New node #{Hexate.encode(node_id)} #{host}:#{port}" end
    {:ok, socket} = :gen_udp.open 0
    Logger.debug fn -> {:ok, port} = :inet.port(socket); "Listening to port #{port}" end
    {:ok, %{id: node_id, host: to_char_list(host), port: port, socket: socket, transactions: HashDict.new, trans_refs: HashDict.new}}
  end

  def terminate(_reason, _state = %{id: id, host: host, port: port}) do
    Logger.debug fn -> "Tearing down node #{Hexate.encode(id)} #{host}:#{port}" end
    :ok
  end

  def handle_call(:add_trans, _from, state = %{transactions: transactions, trans_refs: trans_refs}) do
    trans_id = Utils.random_trans_id
    {:ok, pid} = Transaction.start_link(trans_id)
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
    data
    |> Enum.reduce("", fn(x, acc) -> acc <> <<x>> end)
    |> Bencode.decode!
    {:noreply, state}
  end

  def handle_info({:DOWN, ref, :process, _pid, reason}, state = %{transactions: transactions, trans_refs: trans_refs}) do
    {trans, refs} = Dict.pop trans_refs, ref
    transactions = Dict.delete transactions, trans
    Logger.debug "Transaction #{Hexate.encode(trans)} down due to reason: #{reason}"
    {:noreply, %{state | transactions: transactions, trans_refs: refs}}
  end

  def handle_info(msg, state) do
    IO.inspect msg
    {:noreply, state}
  end

end
