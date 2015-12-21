defmodule ExDHT do
  use Application
  require Logger
  
  @max_bootstrap_attempts 5
  @bootstrap_target_nodes 16
  @bootstrap_attemp_timeout 5

  def start(_type, _args) do
    case ExDHT.Supervisor.start_link do
      {:ok, pid} -> {:ok, pid}
      other -> {:error, other}
    end
  end

  def stop(_state) do
    {:ok}
  end

  def bootstrap do
    [{"router.bittorrent.com", 6881},
     {"router.utorrent.com", 6881},
     {"dht.transmissionbt.com", 6881}]
    |> Enum.each(fn {host, port} ->
      {:ok, _pid} = ExDHT.Node.create host, port
    end)
    do_bootstrap(0)
  end

  defp do_bootstrap(@max_bootstrap_attempts) do
    Logger.error "Bootstrap failed..."
    :error
  end

  defp do_bootstrap(attempt) do
    %{active: active_nodes} = Supervisor.count_children(ExDHT.Supervisor)
    if active_nodes < @bootstrap_target_nodes do
      Logger.info "Bootstrap attempt ##{attempt + 1} with #{active_nodes} nodes."
      find_node_all
      :timer.sleep(@bootstrap_attemp_timeout * 1000)
      do_bootstrap(attempt + 1)
    else
      Logger.info "Found #{active_nodes} nodes, should be enough."
      :ok
    end
  end

  def find_node_all do
    Supervisor.which_children(ExDHT.Supervisor)
    |> Enum.each(fn
      {_id, pid, :supervisor, [ExDHT.Node.Supervisor]} ->
        ExDHT.Node.find_node pid
      _ -> :ok
    end)
  end

end
