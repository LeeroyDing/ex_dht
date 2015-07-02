defmodule ElkDHT.Node.Supervisor do
  use Supervisor

  def start_link, do: Supervisor.start_link __MODULE__, [], [name: __MODULE__]

  def start_child(host, port), do: Supervisor.start_child host, port

  def init([]) do
    children = [
      worker(ElkDHT.Node, [])
    ]
    supervise children, strategy: :simple_one_for_one
  end
end
