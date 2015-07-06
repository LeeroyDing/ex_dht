defmodule ElkDHT.Node.Transaction.Supervisor do
  use Supervisor
  require Logger

  def start_link(host, port) do
    Logger.debug "Starting transaction supervisor for #{host}:#{port}"
    Supervisor.start_link __MODULE__, [host, port], [name: __MODULE__]
  end

  def start_child(node_pid) do
    Supervisor.start_child __MODULE__, [node_pid]
  end

  def init([host, port]) do
    children = [
      worker(ElkDHT.Node.Transaction.Worker, [host, port])
    ]
    supervise children, strategy: :simple_one_for_one
  end
  
end
