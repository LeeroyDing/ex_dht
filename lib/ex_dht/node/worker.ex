defmodule ExDHT.Node.Worker do
  use GenServer
  require Logger
  alias ExDHT.Utils
  alias ExDHT.Node.Transaction
  alias __MODULE__.EventHandler

  defmodule State, do: defstruct id: nil, host: nil, port: nil, socket: nil, event_manager: nil, trans_sup: nil

  @ping_interval 10000
  @life_count 30
  
  def start_link(host, port, event_manager, node_id) do
    GenServer.start_link __MODULE__, [host, port, event_manager, node_id]
  end

  def socket(pid) do
    {:ok, _socket} = GenServer.call pid, :get_socket
  end

  def send_message(pid, type) do
    trans_id = start_trans(pid, type)
    :ok = GenServer.cast pid, {:send_message, type, trans_id}
  end

  def set_trans_sup(pid, trans_sup) do
    {:ok, ^trans_sup} = GenServer.call pid, {:set_trans_sup, trans_sup}
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

  defp start_trans(pid, type) do
    GenServer.call pid, {:start_trans, type}
  end

  def init([host, port, event_manager, node_id]) do
    GenEvent.add_mon_handler event_manager, EventHandler, self
    Logger.debug fn -> "New node #{Hexate.encode(node_id)} #{host}:#{port}" end
    {:ok, socket} = :gen_udp.open 0
    Logger.debug fn -> {:ok, port} = :inet.port(socket); "Listening to port #{port}" end
    GenEvent.sync_notify event_manager, {:worker_init, self}
    Utils.seed
    {:ok, %State{id: node_id, host: to_char_list(host), port: port, socket: socket, event_manager: event_manager}}
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

  def handle_call({:set_trans_sup, trans_sup}, _from, state) do
    {:reply, {:ok, trans_sup}, %State{state | trans_sup: trans_sup}}
  end
  
  def handle_call({:start_trans, type}, _from, state) do
    trans_id = Utils.random_trans_id
    {:ok, _pid} = Transaction.Supervisor.start_child(state.trans_sup, trans_id, type)
    {:reply, trans_id, state}
  end

  def handle_call(:get_node_id, _from, %State{id: id} = state) do
    {:reply, id, state}
  end

  def handle_call(:get_socket, _from, %State{socket: socket} = state) do
    {:reply, socket, state}
  end

  def handle_info({:udp, socket, {a, b, c, d}, port, data}, %State{port: port, socket: socket, event_manager: event_manager} = state) do
    Logger.debug "Message received from #{a}.#{b}.#{c}.#{d}:#{port}"
    decoded = data
    |> Enum.reduce("", fn(x, acc) -> acc <> <<x>> end)
    |> Bencode.decode!
    trans_id = decoded["t"]
    GenEvent.sync_notify event_manager, {:message_received, trans_id, decoded}
    {:noreply, state}
  end

  defmodule EventHandler do
    use GenEvent
    alias ExDHT.Node.Worker
    require Logger
    def handle_event({:trans_sup_init, pid}, parent) do
      Worker.set_trans_sup parent, pid
      {:ok, parent}
    end
    def handle_event(_msg, state), do: {:ok, state}
  end
end
