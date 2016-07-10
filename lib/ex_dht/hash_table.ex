defmodule ExDHT.HashTable do
  use GenServer

  ## Public API

  def start_link do
    GenServer.start_link __MODULE__, [], name: __MODULE__
  end

  @spec add_hash(String.t) :: atom
  def add_hash(hash) do
    GenServer.call __MODULE__, {:add_hash, hash}
  end

  @spec remove_hash(String.t) :: atom
  def remove_hash(hash) do
    GenServer.call __MODULE__, {:remove_hash, hash}
  end

  @spec has_hash?(String.t) :: atom
  def has_hash?(hash) do
    GenServer.call __MODULE__, {:has_hash?, hash}
  end

  @spec add_peer(String.t, String.t) :: atom
  def add_peer(hash, peer) do
    GenServer.call __MODULE__, {:add_peer, hash, peer}
  end

  @spec remove_peer(String.t, String.t) :: atom
  def remove_peer(hash, peer) do
    GenServer.call __MODULE__, {:remove_peer, hash, peer}
  end
  
  @spec has_peer?(String.t, String.t) :: boolean | :error
  def has_peer?(hash, peer) do
    GenServer.call __MODULE__, {:has_peer?, hash, peer}
  end
  
  ## Server callbacks

  def init([]) do
    {:ok, %{}}
  end

  def handle_call({:add_hash, hash}, _from, ht) do
    result = Map.put_new ht, hash, %MapSet{}
    {:reply, :ok, result}
  end

  def handle_call({:remove_hash, hash}, _from, ht) do
    result = Map.delete ht, hash
    {:reply, :ok, result}
  end

  def handle_call({:has_hash?, hash}, _from, ht) do
    result = Map.has_key? ht, hash
    {:reply, result, ht}
  end

  def handle_call({:add_peer, hash, peer}, _from, ht) do
    case Map.fetch(ht, hash) do
      {:ok, peers} ->
        new_peers = MapSet.put(peers, peer)
        new_ht = Map.put(ht, hash, new_peers)
        {:reply, :ok, new_ht}
      :error -> {:reply, :error, ht}
    end
  end

  def handle_call({:remove_peer, hash, peer}, _from, ht) do
    case Map.fetch(ht, hash) do
      {:ok, peers} ->
        new_peers = MapSet.delete(peers, peer)
        new_ht = Map.put(ht, hash, new_peers)
        {:reply, :ok, new_ht}
      :error -> {:reply, :error, ht}
    end
  end

  def handle_call({:has_peer?, hash, peer}, _from, ht) do
    case Map.fetch(ht, hash) do
      {:ok, peers} ->
        {:reply, MapSet.member?(peers, peer), ht}
      :error -> {:reply, :error, ht}
    end
  end

end
