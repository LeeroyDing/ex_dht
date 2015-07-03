defmodule ElkDHT.Node.Transaction.Worker do
  use GenServer

  def start_link(socket) do
    GenServer.start_link __MODULE__, [socket]
  end

  def init([socket]) do
    trans_id = ElkDHT.Utils.random_trans_id
    {:ok, %{id: trans_id, socket: socket}}
  end
  
end
