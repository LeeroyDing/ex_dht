defmodule ElkDHT.Supervisor do
  use Supervisor

  def start_link, do: Supervisor.start_link __MODULE__, [], [name: __MODULE__]

  def init([]) do
    children = [
      supervisor(ElkDHT.Node.Supervisor, [])
    ]
  end
end
