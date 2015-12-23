defmodule ExDHT.Node.Suicider do
  use GenServer
  alias __MODULE__.EventHandler
  
  defmodule State, do: defstruct max_life_count: nil, life_count: nil, node: nil

  def start_link(life_count, node, event_manager) do
    GenServer.start_link __MODULE__, [life_count, node, event_manager]
  end

  def timeout(pid) do
    GenServer.cast pid, :timeout
  end

  def revive(pid) do
    GenServer.cast pid, :revive
  end

  def init([life_count, node, event_manager]) do
    GenEvent.add_mon_handler event_manager, EventHandler, self
    {:ok, %State{max_life_count: life_count, life_count: life_count, node: node}}
  end

  def handle_cast(:timeout, %State{life_count: 0} = state) do
    {:stop, :normal, state}
  end

  def handle_cast(:timeout, state) do
    {:noreply, %State{state | life_count: state.life_count - 1}}
  end

  def handle_cast(:revive, state) do
    {:noreply, %State{state | life_count: state.max_life_count}}
  end

  def terminate(:normal, %State{life_count: 0} = state) do
    ExDHT.Node.stop state.node
    :stop
  end

  defmodule EventHandler do
    use GenEvent
    alias ExDHT.Node.Suicider
    def handle_event({:transaction_timeout, _id, _type}, parent) do
      Suicider.timeout parent
      {:ok, parent}
    end
    def handle_event({:message_received, _id, _message}, parent) do
      Suicider.revive parent
      {:ok, parent}
    end
    def handle_event(_msg, state), do: {:ok, state}
  end
end
