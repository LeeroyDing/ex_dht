defmodule ExDHT.ResponseHandler do
  use GenServer
  alias ExDHT.Node

  def start_link(event_manager), do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  def init(event_manager) do
    :ok = GenEvent.add_mon_handler event_manager, EventHandler, self
    {:ok, []}
  end

  def handle_cast({:ping,
                   %{"y" => "r",
                     "r" => %{"id" => node_id}
                    } = message,
                   {ip, port} = from
                  }, state) do
    case Node.get_node_by_id(node_id) do
      {:ok, pid} ->
        Node.handle_message(pid, message)
      {:error, :not_found} ->
        raise "Not implemented"
    end
    {:noreply, state}
  end

  def handle_cast({:find_node,
                   %{"y" => "r",
                     "r" => %{"id" => node_id,
                              "nodes" => raw_nodes
                             }
                    } = message,
                   {ip, port} = from,
                  }, state) do
    raise "Not implemented"
    {:noreply, state}
  end

  defmodule EventHandler do
    use GenEvent
    alias ExDHT.ResponseHandler
    
    def handle_event({:udp_message_received, message}, parent) do
      raise "Not implemented"
    end
    
    def handle_event(_msg, state), do: {:ok, state}
  end
  
end

