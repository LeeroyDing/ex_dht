defmodule ExDHT.Socket do
  use GenServer
  
  def start_link(event_manager), do: GenServer.start_link(__MODULE__, [event_manager])

  def init([event_manager]) do
    {:ok, socket} = :gen_udp.open 0
    {:ok, [event_manager, socket]}
  end

  def terminate(reason, [event_manager, socket]) do
    GenEvent.notify event_manager, {:stop, reason}
    :gen_udp.close socket
    :stop
  end
  
end
