defmodule ExDHT.Supervisor do
  use Supervisor
  require Logger

  def start_link, do: Supervisor.start_link(__MODULE__, [], [name: __MODULE__])

  def init([]) do
    {:ok, event_manager} = GenEvent.start_link

    children = [
      supervisor(ExDHT.Node.Supervisor, [event_manager]),
      worker(ExDHT.Socket, [event_manager]),
      worker(ExDHT.Node, [ExDHT.Utils.random_node_id]),
      worker(ExDHT.ResponseHandler, [event_manager])
    ]
    supervise children, strategy: :one_for_one
  end

end
