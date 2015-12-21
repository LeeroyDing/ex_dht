defmodule ExDHT.Node.Supervisor do
  use Supervisor
  @timeout 5000
  @ping_interval 30000

  def start_link(host, port, node_id), do: Supervisor.start_link(__MODULE__, [host, port, node_id])

  def init([host, port, node_id]) do
    {:ok, event_manager} = GenEvent.start_link
    
    children = [
      worker(ExDHT.Node.Pinger, [@ping_interval, self]),
#      worker(ExDHT.Node.Suicider, [event_manager]),
      worker(ExDHT.Node.Worker, [host, port, event_manager, node_id], id: :worker),
      supervisor(ExDHT.Node.Transaction.Supervisor, [@timeout, event_manager]),
    ]
    supervise children, strategy: :one_for_all
  end
  
end
