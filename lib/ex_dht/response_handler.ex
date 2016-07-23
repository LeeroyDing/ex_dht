defmodule ExDHT.ResponseHandler do
  use GenServer
  alias ExDHT.Socket

  def start_link do
    GenServer.start_link __MODULE__, [], name: __MODULE__
  end

  defmodule EventProcessor do
    use GenEvent
    def handle_event({:udp, _server, {a, b, c, d} = addr, port, content}, handler) do
      addr = "#{a}.#{b}.#{c}.#{d}"
      case Bencode.decode(content) do
        {:ok, message} ->
          process_message(message, addr, port, handler)
          _ -> :error
      end
    end

    defp process_message(%{"y" => "r"} = message, addr, port, handler) do
      # Process response
      trans_id = Map.get(message, "t")
      args = Map.get(message, "r")
      node_id = Map.get(args, "id")
    end

    defp process_message(%{"y" => "q"} = message, addr, port, handler) do
      # Process query
    end

    defp process_message(%{"y" => "e"} = message, addr, port, handler) do
      # Process error
    end
  end

  def init([]) do
    Socket.add_handler EventProcessor, self
  end

end
