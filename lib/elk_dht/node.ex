defmodule ElkDHT.Node do
  use GenServer
  alias ElkDHT.Utils, as: Utils

  require Logger

  # Public API

  @doc """
  Starts the node.
  """
  def start_link(conf = %{id: node_id, host: _host, port: _port}, opts \\ []) do
    GenServer.start_link __MODULE__, conf, opts ++ [name: node_id]
  end

  @doc """
  Add a transaction to the node.
  """
  def add_trans(node_id, name, info_hash \\ nil) do
    GenServer.call node_id, {:add_trans, name, info_hash}
  end

  @doc """
  Delete a transaction from the node.
  """
  def del_trans(node_id, trans_id) do
    GenServer.cast node_id, {:del_trans, trans_id}
  end

  @doc """
  Update last access time of the node.
  """
  def update_access(node_id) do
    GenServer.cast node_id, {:update_access}
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

  # Private

  defp send_message(node_id, message, socket, trans_id) do
    GenServer.cast node_id, {:send_message, message, socket, trans_id}
  end

  # Callbacks

  def init(%{id: node_id, host: host, port: port}) do
    %{id: node_id, host: host, port: port, trans: HashDict.new, access_time: :os.timestamp}
  end
end
