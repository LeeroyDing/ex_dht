defmodule ExDHT.Node do
  require Logger
  alias ExDHT.Utils
  alias ExDHT.Node.Worker

  def create(host, port) do
    node_id = Utils.random_node_id
    create(host, port, node_id)
  end

  def create(host, port, node_id) do
    case ExDHT.Node.Supervisor.start_child(host, port, node_id) do
      {:ok, pid} ->
        {:ok, pid}
      other ->
        {:error, other}
    end
  end

  def find_node(pid) do
    pid
    |> worker
    |> Worker.send_message :find_node
  end

  def ping(pid) do
    pid
    |> worker
    |> Worker.send_message :ping
  end

  def stop(pid) do
    ExDHT.Node.Supervisor.terminate_child pid
  end

  defp worker(pid) do
    Supervisor.which_children(pid)
    |> Enum.find(fn
      {:worker, _pid, :worker, [Worker]} -> true
      _ -> false
    end)
    |> elem(1)
  end
  
end
