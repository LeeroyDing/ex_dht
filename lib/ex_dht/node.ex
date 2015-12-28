defmodule ExDHT.Node do
  use GenServer
  require Logger
  alias ExDHT.Utils
  alias ExDHT.Node.Worker

  # Public functions
  
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

  # Self Node functions

  def start_link(node_id) do
    GenServer.start_link __MODULE__, [node_id], name: __MODULE__
  end

  def init([node_id]) do
    Logger.debug "Self node initiated, id: #{Hexate.encode(node_id)}."
    {:ok, {node_id, HashDict.new}}
  end

  def node_id do
    GenServer.call __MODULE__, :get_id
  end

  def add_trans(trans_id, type) do
    GenServer.call __MODULE__, {:add_trans, trans_id, type}
  end

  def list_trans do
    GenServer.call __MODULE__, :list_trans
  end

  def get_trans(trans_id) do
    GenServer.call __MODULE__, {:get_trans, trans_id}
  end

  def pop_trans(trans_id) do
    GenServer.call __MODULE__, {:pop_trans, trans_id}
  end

  def handle_call(:get_id, _from, {id, _trans} = state) do
    {:reply, id, state}
  end

  def handle_call({:add_trans, trans_id, type}, _from, {id, trans}) do
    trans = trans
    |> Dict.put(trans_id, type)
    {:reply, {trans_id, type}, {id, trans}}
  end
  
  def handle_call(:list_trans, _from, {_id, trans} = state) do
    {:reply, trans, state}
  end

  def handle_call({:get_trans, trans_id}, _from, {_id, trans} = state) do
    case Dict.get(trans, trans_id) do
      nil -> {:reply, nil, state}
      type -> {:reply, {trans_id, type}, state}
    end
  end

  def handle_call({:pop_trans, trans_id}, _from, {id, trans}) do
    case Dict.pop(trans, trans_id) do
      {nil, trans} ->
        {:reply, nil, {id, trans}}
      {type, new_trans} ->
        {:reply, nil, {id, new_trans}}
    end
  end
  
end
