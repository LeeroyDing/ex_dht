defmodule ExDHT.ResponseHandler do
  use GenServer
  alias ExDHT.Node

  def start_link(), do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

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

end
