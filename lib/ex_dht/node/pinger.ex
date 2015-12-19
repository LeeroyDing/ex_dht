defmodule ExDHT.Node.Pinger do
  use GenServer
  require Logger
  defmodule State, do: defstruct node: nil, interval: nil

  def start_link(node, interval) do
    GenServer.start_link __MODULE__, [node, interval]
  end

  def init([node, interval]) do
    {:ok, %State{node: node, interval: interval}, interval}
  end

  def handle_info(:timeout, state) do
    Logger.debug "Ping from automated pinger."
    ExDHT.Node.ping state.node
    {:noreply, state, state.interval}
  end
  
end
