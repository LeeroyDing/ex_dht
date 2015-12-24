defmodule ExDHT.Node.Supervisor do
  use Supervisor

  def start_link(socket_event_manager), do: Supervisor.start_link(__MODULE__, [socket_event_manager], [name: __MODULE__])

  def start_child(host, port, node_id), do: Supervisor.start_child(__MODULE__, [host, port, node_id])

  def terminate_child(child), do: Supervisor.terminate_child __MODULE__, child
  
  def init([socket_event_manager]) do
    children = [
      supervisor(ExDHT.Node.Worker.Supervisor, [socket_event_manager])
    ]
    supervise children, strategy: :simple_one_for_one
  end
  
end
