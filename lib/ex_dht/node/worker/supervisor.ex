defmodule ExDHT.Node.Worker.Supervisor do
  use Supervisor
  # WARNING: make sure ping_interval is greater than timeout
  @timeout 5000
  @ping_interval 10000
  @life_count 3

  def start_link(socket_event_manager, host, port, node_id), do: Supervisor.start_link(__MODULE__, [socket_event_manager, host, port, node_id])

  def init([socket_event_manager, host, port, node_id]) do
    {:ok, event_manager} = GenEvent.start_link
    
    children = [
      worker(ExDHT.Node.Worker.Pinger, [@ping_interval, self]),
      worker(ExDHT.Node.Worker.Suicider, [@life_count, self, event_manager], restart: :temporary),
      worker(ExDHT.Node.Worker, [host, port, event_manager, socket_event_manager, node_id], id: :worker),
      supervisor(ExDHT.Node.Worker.Transaction.Supervisor, [@timeout, event_manager]),
    ]
    
    supervise children, strategy: :one_for_all
  end

end
