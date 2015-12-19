defmodule ExDHT.Node.Transaction do
  use GenServer
  require Logger
  alias ExDHT.Utils

  defmodule State do
    defstruct id: nil, type: nil, parent: nil, start_time: nil, timeout: nil
  end

  @timeout 5000

  def start_link(id, type, parent, timeout \\ @timeout, opts \\ []) do
    GenServer.start_link __MODULE__, [id, type, parent, timeout], opts ++ [timeout: timeout]
  end

  def init([id, type, parent, timeout]) do
    start_time = :os.system_time
    Logger.debug "Transaction #{Hexate.encode(id)} initialized."
    {:ok, %State{id: id, type: type, parent: parent, start_time: start_time, timeout: timeout}, timeout}
  end

  def id(pid) do
    GenServer.call pid, :id
  end

  def process_message(pid, message) do
    GenServer.cast pid, {:process_message, message}
  end

  def handle_call(:id, _from, %State{id: id, start_time: start_time, timeout: timeout}) do
    {:reply, id, {id, start_time}, Utils.time_left(start_time, timeout)}
  end

  def handle_cast({:process_message,
                   %{"r" => %{"id" => node_id, "nodes" => raw_nodes}, "t" => id, "y" => "r"}},
                  %State{id: id, type: :find_node} = state) do
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
                  %State{id: id, type: :ping} = state) do
    Logger.info "Pong from node #{Hexate.encode(node_id)}."
    {:stop, :normal, state}
  end

  def handle_info(:timeout, %State{id: id, type: type} = state) do
    Logger.debug "Transaction #{Hexate.encode(id)} (#{type}) timed out."
    {:stop, :normal, state}
  end

end
