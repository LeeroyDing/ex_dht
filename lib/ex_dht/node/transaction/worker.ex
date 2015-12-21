defmodule ExDHT.Node.Transaction.Worker do
  use GenServer
  require Logger
  alias __MODULE__.EventHandler
  alias ExDHT.Utils

  defmodule State, do: defstruct event_manager: nil, id: nil, type: nil

  def start_link(timeout, event_manager, id, type), do: GenServer.start_link __MODULE__, [timeout, event_manager, id, type]

  def process_message(pid, message) do
    GenServer.cast pid, {:process_message, message}
  end
                      
  def init([timeout, event_manager, id, type]) do
    Logger.debug "Transaction #{Hexate.encode(id)} (#{type}) started."
    GenEvent.add_mon_handler event_manager, EventHandler, {id, type, self}
    {:ok, %State{event_manager: event_manager, id: id, type: type}, timeout}
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

  def handle_info(:timeout, %State{id: id, type: type, event_manager: event_manager} = state) do
    Logger.debug "Transaction #{Hexate.encode(id)} (#{type}) timed out."
    GenEvent.notify event_manager, {:transaction_timeout, id, type}
    {:stop, :normal, state}
  end

  def terminate(reason, %State{event_manager: event_manager, id: id, type: type}) do
    Logger.debug "Transaction #{Hexate.encode(id)} ended."
    GenEvent.notify event_manager, {:transaction_terminate, reason, id, type}
    GenEvent.remove_handler event_manager, EventHandler, {id, type, self}
    :stop
  end

  defmodule EventHandler do
    use GenEvent
    alias ExDHT.Node.Transaction.Worker
    def handle_event({:message_received, id, message}, {id, _type, parent} = state) do
      Worker.process_message parent, message
      {:ok, state}
    end
    def handle_event(_msg, state), do: {:ok, state}
  end
  
end
