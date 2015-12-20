defmodule ExDHT.Node.Supervisor do
  use Supervisor

  def start_link(host, port), do: Supervisor.start_link(__MODULE__, [host, port], [name: __MODULE__])

  def init([host, port]) do
    {:ok, event_manager} = GenEvent.start_link
    
    children = [
      worker(ExDHT.Node.Worker, [host, port, event_manager]),
      worker(ExDHT.Node.Pinger, [event_manager]),
      worker(ExDHT.Node.Suicider, [event_manager]),
      supervisor(ExDHT.Node.Transaction.Supervisor, [host, port, event_manager])
    ]
    supervise children, strategy: :one_for_all
  end
end
