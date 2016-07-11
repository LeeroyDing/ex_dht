defmodule ExDHT.Socket do
  use GenServer
  require Logger
  alias ExDHT.Socket

  defstruct event_manager: nil, socket: nil, port: 0
  
  ## Public interface

  def start_link do
    GenServer.start_link __MODULE__, 0, name: __MODULE__
  end

  @spec add_handler(GenEvent.handler, term) :: :ok
  def add_handler(handler, term \\ []) do
    GenServer.cast __MODULE__, {:add_handler, handler, term}
  end

  @spec remove_handler(GenEvent.handler, term) :: :ok
  def remove_handler(handler, term \\ []) do
    GenServer.cast __MODULE__, {:remove_handler, handler, term}
  end

  @spec port :: integer | :error
  def port do
    GenServer.call __MODULE__, :port
  end

  @spec send_message(bitstring(), bitstring(), integer) :: :ok
  def send_message(message, address, port) do
    GenServer.cast __MODULE__, {:send_message, message, address, port}
  end

  ## Server callbacks
  def init(port) do
    {:ok, socket} = :gen_udp.open(port, [:binary, {:active, true}])
    {:ok, port} = :inet.port(socket)
    Logger.debug "Server started on port #{port}"
    {:ok, event_manager} = GenEvent.start_link
    {:ok, %Socket{event_manager: event_manager, socket: socket, port: port}}
  end

  def handle_cast({:add_handler, handler, term}, state) do
    GenEvent.add_handler state.event_manager, handler, term
    {:noreply, state}
  end

  def handle_cast({:remove_handler, handler, term}, state) do
    GenEvent.remove_handler state.event_manager, handler, term
    {:noreply, state}
  end

  def handle_cast({:send_message, message, address, port}, state) do
    :gen_udp.send(state.socket, to_char_list(address), port, message)
    {:noreply, state}
  end

  def handle_call(:port, _from, state) do
    {:reply, state.port, state}
  end

  def handle_info({:udp, _socket, addr, port, msg}, state) do
    GenEvent.notify(state.event_manager, {addr, port, msg})
    {:noreply, state}
  end
  
end
