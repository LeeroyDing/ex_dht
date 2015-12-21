defmodule ExDHT.Node.Pinger do
  use GenServer
  require Logger
  defmodule State, do: defstruct node: nil, interval: nil

  def start_link(interval, node) do
    GenServer.start_link __MODULE__, [interval, node]
  end

  def init([interval, node]) do
    {:ok, %State{node: node, interval: interval}, interval}
  end

  def handle_info(:timeout, state) do
    ExDHT.Node.ping state.node
    {:noreply, state, state.interval}
  end

end
