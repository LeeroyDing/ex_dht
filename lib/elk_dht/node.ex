defmodule ElkDHT.Node do
  use GenServer

  @doc """
  Starts the node.
  """
  def start_link(conf = %{id: node_id, host: _host, port: _port}, opts \\ []) do
    GenServer.start_link __MODULE__, conf, opts ++ [name: node_id]
  end

  def init(%{id: node_id, host: host, port: port}) do
    %{id: node_id, host: host, port: port, trans: HashDict.new, access_time: :os.timestamp}
  end
end
