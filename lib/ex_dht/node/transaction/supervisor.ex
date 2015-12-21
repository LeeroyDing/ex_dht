defmodule ExDHT.Node.Transaction.Supervisor do
  use Supervisor

  def start_link(timeout, event_manager), do: Supervisor.start_link(__MODULE__, [timeout, event_manager])

  def start_child(pid, trans_id, type), do: Supervisor.start_child(pid, [trans_id, type])

  def init([timeout, event_manager]) do
    GenEvent.notify event_manager, {:trans_sup_init, self}
    children = [
      worker(ExDHT.Node.Transaction.Worker, [timeout, event_manager], restart: :temporary)
    ]

    supervise children, strategy: :simple_one_for_one
  end
  
end
