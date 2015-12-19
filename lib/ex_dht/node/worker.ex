defmodule ExDHT.Node.Worker do
  use GenServer
  require Logger
  alias ExDHT.Utils
  alias ExDHT.Node.Transaction
  alias ExDHT.Node.Suicider
  alias ExDHT.Node.Pinger

  @ping_interval 3000
  @suicider_timeout 30000  # 30 seconds before suicide
  @life_count 30

  defmodule State, do: defstruct id: nil, host: nil, port: nil, socket: nil, transactions: nil, trans_refs: nil, suicider: nil

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
    {:ok, suicider} = Suicider.start_link @suicider_timeout, @life_count
    {:ok, _pinger} = Pinger.start_link self, @ping_interval
    {:ok, %State{id: node_id, host: to_char_list(host), port: port, socket: socket, transactions: HashDict.new, trans_refs: HashDict.new, suicider: suicider}}
  end

  def terminate(_reason, _state = %{id: id, host: host, port: port}) do
    Logger.debug fn -> "Tearing down node #{Hexate.encode(id)} #{host}:#{port}" end
    :ok
  end

  def handle_call(:add_trans, _from, state) do
    trans_id = Utils.random_trans_id
    {:ok, pid} = Transaction.start_link(trans_id)
    ref = Process.monitor pid
    transactions = Dict.put state.transactions, trans_id, pid
    trans_refs = Dict.put state.trans_refs, ref, trans_id
    {:reply, trans_id, %{state | transactions: transactions, trans_refs: trans_refs}}
  end

  def handle_call(:get_node_id, _from, state) do
    {:reply, state.id, state}
  end

  def handle_call(:get_socket, _from, state) do
    {:reply, state.socket, state}
  end

  def handle_call({:get_trans, trans_id}, _from, state) do
    {:reply, Dict.fetch!(state.transactions, trans_id), state}
  end

  def handle_info({:udp, socket, {a, b, c, d}, port, data}, %State{port: port, socket: socket} = state) do
    Logger.debug "Message received from #{a}.#{b}.#{c}.#{d}:#{port}"
    data
    |> Enum.reduce("", fn(x, acc) -> acc <> <<x>> end)
    |> Bencode.decode!
    {:noreply, state}
  end

  def handle_info({:DOWN, ref, :process, suicider, _reason}, %State{suicider: suicider} = state) do
    Logger.info "Haven't heard from node #{Hexate.encode(state.id)} for some time, removing it..."
    {trans, refs} = Dict.pop state.trans_refs, ref
    transactions = Dict.delete state.transactions, trans
    {:stop, :normal, %State{state | transactions: transactions, trans_refs: refs}}
  end

  def handle_info({:DOWN, ref, :process, _pid, _reason}, state) do
    {trans, refs} = Dict.pop state.trans_refs, ref
    transactions = Dict.delete state.transactions, trans
    Logger.debug "Transaction #{Hexate.encode(trans)} down."
    {:noreply, %State{state | transactions: transactions, trans_refs: refs}}
  end

end
