defmodule ElkDHT.Node do
  use GenServer
  alias ElkDHT.Utils, as: Utils

  require Logger

  # Public API

  @doc """
  Starts the node.
  """
  def start_link(host, port, opts \\ []) do
    node_id = Utils.random_node_id
    Logger.debug "New node #{Hexate.encode(node_id}, #{host}:#{port}"
    GenServer.start_link __MODULE__, opts
  end

  def create(host, port) do
    ElkDHT.Node.Supervisor.start_child host, port
  end

  # TODO: refactor
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

  def terminate(_reason, %{id: node_id}) do
  end
  
end
