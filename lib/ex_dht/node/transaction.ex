defmodule ExDHT.Node.Transaction do
  use GenServer
  require Logger
  alias ExDHT.Utils
  @timeout 5
  def start_link(trans_id, type, timeout \\ @timeout, opts \\ []) do
    GenServer.start_link __MODULE__, [trans_id, type, timeout], opts ++ [timeout: timeout]
  end

  def init([trans_id, type, timeout]) do
    start_time = :calendar.local_time |> :calendar.datetime_to_gregorian_seconds
    Logger.debug "Transaction #{Hexate.encode(trans_id)} initialized."
    {:ok, {trans_id, type, start_time, timeout}, timeout * 1000}
  end

  def id(pid) do
    GenServer.call pid, :id
  end

  def process_message(pid, message) do
    GenServer.cast pid, {:process_message, message}
  end

  def handle_call(:id, _from, {id, _type, start_time, timeout}) do
    {:reply, id, {id, start_time}, Utils.time_left(start_time, timeout)}
  end

  def handle_cast({:process_message,
                   %{"r" => %{"id" => node_id, "nodes" => raw_nodes}, "t" => id, "y" => "r"}},
                  {id, :find_node, _start_time, _timeout} = state) do
    Logger.info "Found #{raw_nodes |> byte_size |> div(26)} new nodes from node #{Hexate.encode(node_id)}."
    raw_nodes
    |> Utils.parse_nodes
    |> Enum.uniq
    |> Enum.each(fn
      {node_id, ip, port} ->
        ExDHT.Node.create ip, port, node_id
    end)
    {:stop, :normal, state}
  end

  def handle_cast({:process_message,
                   %{"r" => %{"id" => node_id}, "t" => id, "y" => "r"}},
                  {id, :ping, _start_time, _timeout} = state) do
    Logger.info "Pong from node #{Hexate.encode(node_id)}."
    {:stop, :pong, state}
  end

  def handle_info(:timeout, {id, :ping, _start_time, _timeout} = state) do
    Logger.debug "Transaction #{Hexate.encode(id)} (:ping) timed out."
    {:stop, :ping_timeout, state}
  end

  def handle_info(:timeout, {id, type, _start_time, _timeout} = state) do
    Logger.debug "Transaction #{Hexate.encode(id)} (#{type}) timed out."
    {:stop, :normal, state}
  end

end
