defmodule ExDHT.Socket do
  use GenServer
  require Logger
  
  def start_link(event_manager), do: GenServer.start_link(__MODULE__, [event_manager], name: __MODULE__)

  def send_message(host, port, message) do
    :ok = GenServer.call __MODULE__, {:send_message, host, port, message}
  end

  def init([event_manager]) do
    {:ok, socket} = :gen_udp.open 0
    Logger.debug fn -> {:ok, port} = :inet.port(socket); "Listening to port #{port}" end
    {:ok, {event_manager, socket}}
  end

  def handle_call({:send_message, host, port, message}, _from, {event_manager, socket} = state) do
    encoded = Bencode.encode!(message)
    :ok = :gen_udp.send socket, host, port, [encoded]
    GenEvent.notify event_manager, {:udp_message_sent, message}
    {:reply, :ok, state}
  end

  def handle_info({:udp, socket, {a, b, c, d}, port, data}, {event_manager, socket} = state) do
    Logger.debug "Message received from #{a}.#{b}.#{c}.#{d}:#{port}"
    decoded = data
    |> Enum.reduce("", fn(x, acc) -> acc <> <<x>> end)
    |> Bencode.decode!
    Logger.debug fn -> "Notifying #{GenEvent.which_handlers(event_manager) |> Enum.count} nodes for UDP event..." end
    GenEvent.notify event_manager, {:udp_message_received, decoded}
    {:noreply, state}
  end

  def terminate(reason, [event_manager, socket]) do
    :gen_udp.close socket
    GenEvent.notify event_manager, {:socket_close, reason}
    :stop
  end

end
