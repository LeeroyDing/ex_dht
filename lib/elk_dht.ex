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
    {:ok, sup} = ElkDHT.Node.create "router.bittorrent.com", 6881
    [{ElkDHT.Node.Worker, worker, _, _}] =
      Supervisor.which_children(sup)
    |> Enum.filter(fn {ElkDHT.Node.Worker, _, _, _} -> true; _ -> false end)
    ElkDHT.Node.find_node worker
  end
end
