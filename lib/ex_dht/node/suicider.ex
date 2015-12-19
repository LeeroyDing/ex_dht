defmodule ExDHT.Node.Suicider do
  use GenServer
  
  defmodule State, do: defstruct timeout: nil, max_life_count: nil, life_count: nil

  def start_link(timeout, life_count) do
    start_time = :os.system_time
    GenServer.start_link __MODULE__, [timeout, life_count]
  end

  def revive(pid) do
    GenServer.cast pid, :revive
  end

  def init([timeout, life_count]) do
    {:ok, %State{timeout: timeout, max_life_count: life_count, life_count: life_count}, timeout}
  end

  def handle_cast(:revive, state) do
    {:noreply, %State{state | timeout: state.max_life_count}, state.timeout}
  end

  def handle_info(:timeout, %State{life_count: 0} = state) do
    {:stop, :normal, state}
  end
  
  def handle_info(:timeout, state) do
    {:noreply, %State{state | life_count: state.life_count - 1}}
  end

end
