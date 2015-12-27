defmodule ExDHT.RequestHandler do
  use GenServer

  def start_link(), do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  def handle_cast({:ping, %{"y" => "r", "r" => %{"id" => node_id}} = message}, state) do
    # TODO: implement
    {:noreply, state}
  end

  def handle_cast({:find_node, %{"y" => "r", "r" => %{"id" => node_id, "nodes" => raw_nodes}} = message}, state) do
    #TODO: implement
    {:noreply, state}
  end

end
