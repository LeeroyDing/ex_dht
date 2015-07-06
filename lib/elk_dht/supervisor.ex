defmodule ElkDHT.Supervisor do
  use Supervisor
  require Logger

  def start_link, do: Supervisor.start_link(__MODULE__, [], [name: __MODULE__])

  def start_child(host, port), do: Supervisor.start_child(__MODULE__, [host, port])

  def init([]) do
    children = [
      supervisor(ElkDHT.Node.Supervisor, [])
    ]
    supervise children, strategy: :simple_one_for_one
  end
  
end
