defmodule ExDHT.RouteTable do
  use GenServer
  alias ExDHT.Utils
  alias ExDHT.Node
  defstruct nodes: %{}, bad_nodes: %{}
  
  # Public 
  def start_link do
    GenServer.start_link __MODULE__, [], name: __MODULE__
  end

  def get_close_nodes(target, num \\ 3) do
    GenServer.call __MODULE__, {:get_close_nodes, target, num}
  end

  def update_node(node_id, node) do
    GenServer.call __MODULE__, {:update_node, node_id, node}
  end

  def remove_node(node_id) do
    GenServer.call __MODULE__, {:remove_node, node_id}
  end

  def get_nodes do
    GenServer.call __MODULE__, :get_nodes
  end

  def count do
    GenServer.call __MODULE__, :count
  end

  def bad_count do
    GenServer.call __MODULE__, :bad_count
  end

  def node_by_trans(trans_id) do
    GenServer.call __MODULE__, {:node_by_trans, trans_id}
  end

  def node_by_id(node_id) do
    GenServer.call __MODULE__, {:node_by_id, node_id}
  end

  def sample(num) do
    GenServer.call __MODULE__, {:sample, num}
  end

  # Callbacks
  def init([]) do
    {:ok, %__MODULE__{}}
  end

  def handle_call({:get_close_nodes, target, num}, _from, state) do
    sort_mapper = fn {node_id, _node} -> Utils.string_xor(node_id, target) end
    nodes = state.nodes
    |> Enum.sort_by(sort_mapper)
    |> Enum.take(num)
    {:reply, nodes, state}
  end

  def handle_call({:update_node, node_id, node}, _from, state) do
    if Map.has_key?(state.bad_nodes, node_id) do
      {:reply, :bad_node, state}
    else
      nodes = Map.put(state.nodes, node_id, node)
      Node.update_access(node)
      {:reply, :ok, %{state | nodes: nodes}}
    end
  end

  def handle_call({:remove_node, node_id}, _from, state) do
    case Map.fetch(state.nodes, node_id) do
      {:ok, node} -> {:reply, :ok,
                     %{nodes: Map.drop(state.nodes, node_id),
                       bad_nodes: Map.put(state.bad_nodes, node_id, node)
                     }}
      :error -> {:reply, :ok, state}
    end
  end

  def handle_call(:get_nodes, _from, state) do
    {:reply, state.nodes, state}
  end

  def handle_call(:count, _from, state) do
    {:reply, Enum.count(state.nodes), state}
  end

  def handle_call(:bad_count, _from, state) do
    {:reply, Enum.count(state.bad_nodes), state}
  end

  def handle_call({:node_by_trans, trans_id}, _from, state) do
    node = state.nodes
    |> Map.values
    |> Enum.filter(fn n ->
      Node.get_trans(n)
      |> Enum.member?(trans_id)
    end)
    |> Enum.take(1)
    {:reply, node, state}
  end

  def handle_call({:node_by_id, node_id}, _from, state) do
    node = state.nodes
    |> Map.values
    |> Enum.filter(fn n ->
      Node.id(n) === node_id
    end)
    |> Enum.take(1)
    {:reply, node, state}
  end

  def handle_call({:sample, num}, _from, state) do
    {:reply, Enum.take_random(state.nodes, num), state}
  end
  
end
