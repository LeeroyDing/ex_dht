defmodule ElkDHT.Node.Supervisor do
  use Supervisor

  def start_link(socket, host, port), do: Supervisor.start_link(__MODULE__, [socket, host, port], [name: __MODULE__])

  def init([socket, host, port]) do
    children = [
      worker(ElkDHT.Node.Worker, [host, port]),
      supervisor(ElkDHT.Node.Transaction.Supervisor, [socket])
    ]
    supervise children, strategy: :one_for_one
  end
end
