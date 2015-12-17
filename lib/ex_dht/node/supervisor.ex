defmodule ExDHT.Node.Supervisor do
  use Supervisor

  def start_link(host, port), do: Supervisor.start_link(__MODULE__, [host, port], [name: __MODULE__])

  def init([host, port]) do
    children = [
      worker(ExDHT.Node.Worker, [host, port]),
      supervisor(ExDHT.Node.Transaction.Supervisor, [host, port])
    ]
    supervise children, strategy: :one_for_all
  end
end
