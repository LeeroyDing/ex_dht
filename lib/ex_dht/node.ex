defmodule ExDHT.Node do
  use GenServer
  require Logger
  alias ExDHT.Utils
  alias ExDHT.Node.Worker

  defmodule State, do: defstruct id: nil, host: nil, port: nil, socket: nil, transactions: nil, trans_refs: nil, suicider: nil

  def create(host, port) do
    node_id = Utils.random_node_id
    create(host, port, node_id)
  end

  def create(host, port, node_id) do
    case ExDHT.Supervisor.start_child(host, port, node_id) do
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

  defp worker(pid) do
    Supervisor.which_children(pid)
    |> Enum.find(fn
      {:worker, _pid, :worker, [Worker]} -> true
      _ -> false
    end)
    |> elem(1)
  end
  
end
