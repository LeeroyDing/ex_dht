defmodule ElkDHT.Node do
  use GenServer
  alias ElkDHT.Utils, as: Utils

  require Logger

  # Public API

  @doc """
  Starts the node.
  """
  def start_link(conf = %{id: node_id, host: host, port: port}, opts \\ []) do
    Logger.debug "Starting a new node #{Hexate.encode(node_id)}: #{host}:#{port}"
    GenServer.start_link __MODULE__, conf, opts ++ [name: String.to_atom("#{Hexate.encode(node_id)}")]
  end

  @doc """
  Add a transaction to the node.
  """
  def add_trans(node_id, name, info_hash \\ nil) do
    call node_id, {:add_trans, name, info_hash}
  end

  @doc """
  Delete a transaction from the node.
  """
  def del_trans(node_id, trans_id) do
    cast node_id, {:del_trans, trans_id}
  end

  @doc """
  Update last access time of the node.
  """
  def update_access(node_id) do
    cast node_id, {:update_access}
  end

  @doc """
  Send ping to the node.
  """
  def ping(node_id, socket, sender_id) do
    trans_id = add_trans node_id, "ping"
    message = %{ "y" => "q",
                 "q" => "ping",
                 "a" => %{ "id" => sender_id }
               }
    Logger.debug "ping msg to #{node_id}, t: #{Hexate.encode(trans_id)}"
    send_message node_id, message, socket, trans_id
  end

  @doc """
  Send pong to the node.
  """
  def pong(node_id, socket, trans_id, sender_id) do
    message = %{"y" => "r",
                "r" => %{ "id" => sender_id }
               }
    Logger.debug "pong msg to #{node_id}, t: #{Hexate.encode(trans_id)}"
    send_message node_id, message, socket, trans_id
  end

  @doc """
  Send find_node message to the node.
  """
  def find_node(node_id, socket, sender_id) do
    trans_id = add_trans node_id, "find_node"
    message = %{ "y" => "q",
                 "q" => "find_node",
                 "a" => %{ "id" => sender_id,
                           "target" => node_id }
               }
    Logger.debug "find_node msg to #{Hexate.encode(node_id)}"
    send_message node_id, message, socket, trans_id
  end

  @doc """
  Stop the node server.
  """
  def stop(node_id) do
    cast node_id, {:stop}
  end

  # Private

  defp send_message(node_id, message, socket, trans_id) do
    cast node_id, {:send_message, message, socket, trans_id}
  end

  defp call(node_id, args) do
    GenServer.call("#{Hexate.encode(node_id)}" |> String.to_atom, args)
  end

  defp cast(node_id, args) do
    GenServer.cast("#{Hexate.encode(node_id)}" |> String.to_atom, args)
  end

  # Callbacks

  def init(%{id: node_id, host: host, port: port}) do
    Logger.debug "Initializing node #{Hexate.encode(node_id)}, host: #{host}, port: #{port}."
    {:ok, %{id: node_id, host: to_char_list(host), port: port, trans: HashDict.new, access_time: :os.timestamp}}
  end

  def handle_call({:add_trans, name, info_hash}, _from, state = %{trans: trans}) do
    trans_id = Utils.random_trans_id
    trans = HashDict.put trans, trans_id, {name, info_hash, :os.timestamp}
    {:reply, trans_id, %{state | trans: trans}}
  end

  def handle_cast({:del_trans, trans_id}, state = %{trans: trans}) do
    trans = HashDict.delete trans, trans_id
    {:noreply, %{state | trans: trans}}
  end

  def handle_cast({:update_access, state}) do
    {:noreply, %{state | access_time: :os.timestamp}}
  end

  def handle_cast({:send_message, message, socket, trans_id}, state = %{host: host, port: port}) do
    encoded = message
    |> Map.put("v", Utils.get_version)
    |> Map.put("t", trans_id)
    |> Bencode.encode!
    :gen_udp.send socket, host, port, [encoded]
    {:noreply, state}
  end

  def handle_cast({:stop}, _) do
    {:stop, :normal}
  end
end
