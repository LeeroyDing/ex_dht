defmodule ExDHT.Node do
  use GenServer
  alias ExDHT.Socket
  alias ExDHT.Utils

  defstruct id: "", host: "", port: 0, trans: %{}, tokens: %{}, local_tokens: %{}, access_time: :os.system_time

  ## Public interface

  @spec start_link(String.t, integer, bitstring()) :: GenServer.on_start
  def start_link(host, port, id) do
    GenServer.start_link __MODULE__, {host, port, id}
  end

  @doc "Generate and add new transaction"
  @spec add_trans(pid(), String.t, bitstring() | nil) :: bitstring()
  def add_trans(node, name, info_hash \\ nil) do
    GenServer.call node, {:add_trans, name, info_hash}
  end

  @doc "Delete specified transaction"
  @spec delete_trans(pid(), bitstring()) :: :ok | :error
  def delete_trans(node, trans_id) do
    GenServer.call node, {:delete_trans, trans_id}
  end

  @doc "Adds a token for a given info hash as generated by this node"
  @spec add_token(pid(), bitstring(), bitstring()) :: :ok | :error
  def add_token(node, info_hash, token) do
    GenServer.call node, {:add_token, info_hash, token}
  end

  @doc "Returns token for the info hash, if known"
  @spec get_token(pid(), bitstring()) :: bitstring() | nil
  def get_token(node, info_hash) do
    GenServer.call node, {:get_token, info_hash}
  end

  @doc "Delete specified info hash's token"
  @spec delete_token(pid(), bitstring()) :: :ok | :error
  def delete_token(node, info_hash) do
    GenServer.call node, {:delete_token, info_hash}
  end

  @doc "Adds a locally created token for a given info hash for this node"
  @spec add_local_token(pid(), bitstring(), bitstring()) :: :ok | :error
  def add_local_token(node, info_hash, token) do
    GenServer.call node, {:add_local_token, info_hash, token}
  end

  @doc "Returns locally created token for the info hash, if known"
  @spec get_local_token(pid(), bitstring()) :: bitstring() | nil
  def get_local_token(node, info_hash) do
    GenServer.call node, {:get_local_token, info_hash}
  end

  @doc "Delete specified info hash's locally created token"
  @spec delete_local_token(pid(), bitstring()) :: :ok | :error
  def delete_local_token(node, info_hash) do
    GenServer.call node, {:delete_local_token, info_hash}
  end

  @doc "Update last access/modify time of this node"
  @spec update_access(pid(), integer) :: :ok | :error
  def update_access(node, system_time \\ nil) do
    system_time = case system_time do
                    nil -> :os.system_time
                    x -> x
                  end
    GenServer.call node, {:update_access, system_time}
  end

  ## Server callback

  def init({host, port, id}) do
    {:ok, %__MODULE__{host: host, port: port, id: id}}
  end

  def handle_call({:add_trans, name, info_hash}, _from, state) do
    trans_id = Utils.random_trans_id()
    trans = Map.put(
      state.trans, trans_id, %{
        "name" => name,
        "info_hash" => info_hash,
        "access_time" => :os.system_time
      }
    )
    {:reply, trans_id, %{state | trans: trans}}
  end

  def handle_call({:delete_trans, trans_id}, _from, state) do
    trans = Map.delete(state.trans, trans_id)
    {:reply, :ok, %{state | trans: trans}}
  end

  def handle_call({:add_token, info_hash, token}, _from, state) do
    tokens = Map.put_new(state.tokens, info_hash, token)
    {:reply, :ok, %{state | tokens: tokens}}
  end

  def handle_call({:get_token, info_hash}, _from, state) do
    {:reply, Map.get(state.tokens, info_hash), state}
  end

  def handle_call({:delete_token, info_hash}, _from, state) do
    tokens = Map.delete(state.tokens, info_hash)
    {:reply, :ok, %{state | tokens: tokens}}
  end

  ## Private functions

  @spec send_message(%__MODULE__{}, bitstring(), bitstring() | nil) :: :ok | :error
  defp send_message(state, message, trans_id \\ nil) do
    message = Map.put_new(message, "v", Utils.version)
    message = case trans_id do
                nil -> message
                t -> Map.put_new(message, "t", t)
              end
    encoded = Bencode.encode!(message)
    Socket.send_message(encoded, state.host, state.port)
  end
  
end
