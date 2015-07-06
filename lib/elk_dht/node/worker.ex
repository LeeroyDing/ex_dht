defmodule ElkDHT.Node.Worker do
  use GenServer
  require Logger
  alias ElkDHT.Utils, as: Utils

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
    {:ok, %{id: node_id, host: to_char_list(host), port: port, socket: socket}}
  end

  def terminate(_reason, _state = %{id: id, host: host, port: port}) do
    Logger.debug fn -> "Tearing down node #{Hexate.encode(id)} #{host}:#{port}" end
    :ok
  end

  def handle_call(:get_node_id, _from, state = %{id: id}) do
    {:reply, id, state}
  end

  def handle_call(:get_socket, _from, state = %{socket: socket}) do
    {:reply, socket, state}
  end

  def handle_info({:udp, socket, {a, b, c, d}, port, data}, state = %{port: port, socket: socket}) do
    Logger.debug "Message received from #{a}.#{b}.#{c}.#{d}:#{port}"
    data
    |> Enum.reduce("", fn(x, acc) -> acc <> <<x>> end)
    |> Bencode.decode!
    {:noreply, state}
  end
  
end
