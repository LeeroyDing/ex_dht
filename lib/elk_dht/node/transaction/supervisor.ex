defmodule ElkDHT.Node.Transaction.Supervisor do
  use Supervisor

  def start_link(socket), do: Supervisor.start_link(__MODULE__, [socket], [name: __MODULE__])

  def start_child(id), do: Supervisor.start_child(__MODULE__, [id])

  def init([socket]) do
    children = [
      worker(ElkDHT.Node.Transaction.Worker, [socket])
    ]
    supervise children, strategy: :simple_one_for_one
  end
end
