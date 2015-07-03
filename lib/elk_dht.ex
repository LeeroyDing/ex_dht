defmodule ElkDHT do
  use Application

  def start(_type, _args) do
    case ElkDHT.Supervisor.start_link do
      {:ok, pid} -> {:ok, pid}
      other -> {:error, other}
    end
  end

  def stop(_state) do
    {:ok}
  end

  def bootstrap do
    {:ok, id} = ElkDHT.Node.create "router.bittorrent.com", 6881
#    ElkDHT.Node.find_node id
  end
end
