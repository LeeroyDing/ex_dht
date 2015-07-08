defmodule ElkDHT.Node.Transaction do
  use GenServer
  require Logger
  alias ElkDHT.Utils
  @timeout 5
  def start_link(trans_id, type, timeout \\ @timeout, opts \\ []) do
    GenServer.start_link __MODULE__, [trans_id, type, timeout], opts ++ [timeout: timeout]
  end

  def init([trans_id, type, timeout]) do
    start_time = :calendar.local_time |> :calendar.datetime_to_gregorian_seconds
    Logger.debug "Transaction #{Hexate.encode(trans_id)} initialized."
    {:ok, {trans_id, type, start_time, timeout}, timeout * 1000}
  end

  def id(pid) do
    GenServer.call pid, :id
  end

  def process_message(pid, message) do
    """
 %{"ip" => <<120, 32, 238, 205, 196, 241>>,
 "r" => %{"id" => <<50, 245, 78, 105, 115, 81, 255, 74, 236, 41, 205, 186, 171, 242, 251, 227, 70, 124, 194, 103>>,
 "nodes" => <<250, 86, 158, 155, 142, 117, 56, 50, 209, 86, 168, 17, 207, 141, 73, 244, 219, 186, 248, 19, 176, 104, 237, 200, 102, 51, 157, 179, 124, 204, 165, 132, 237, 236, 47, 28, 183, 51, 45, 191, 66, 126, 8, 110, 106, 31, 115, ...>>},
 "t" => <<121, 102, 79, 15>>, "y" => "r"}
    """
    GenServer.cast pid, {:process_message, message}
  end

  def handle_call(:id, _from, {id, _, start_time, timeout}) do
    {:reply, id, {id, start_time}, Utils.time_left(start_time, timeout)}
  end

  def handle_cast({:process_message,
                   %{"r" => %{"id" => node_id, "nodes" => raw_nodes}, "t" => id, "y" => "r"}},
                  {id, :find_node, _, _} = state) do
    Logger.info "Found #{raw_nodes |> byte_size |> div(26)} new nodes from #{Hexate.encode(node_id)}."
    raw_nodes
    |> Utils.parse_nodes
    |> Enum.each(fn
      {node_id, ip, port} ->
        ElkDHT.Node.create ip, port, node_id
    end)
    {:stop, :normal, state}
  end
  
  def handle_info(:timeout, state = {id, type, _, timeout}) do
    Logger.debug "Transaction #{Hexate.encode(id)} (#{type}) timed out."
    {:stop, :normal, state}
  end

end
