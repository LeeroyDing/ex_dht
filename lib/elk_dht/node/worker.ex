defmodule ElkDHT.Node.Worker do
  use GenServer
  require Logger
  alias ElkDHT.Utils, as: Utils

  def start_link(host, port) do
    GenServer.start_link __MODULE__, [host, port]
  end

  def init([host, port]) do
    node_id = Utils.random_node_id
    Logger.debug fn -> "New node #{Hexate.encode(node_id)} #{host}:#{port}" end
    {:ok, %{id: node_id, host: to_char_list(host), port: port}}
  end

  def terminate(_reason, _state = %{id: id, host: host, port: port}) do
    Logger.debug fn -> "Tearing down #{Hexate.encode(id)} #{host}:#{port}" end
    :ok
  end
  
end
