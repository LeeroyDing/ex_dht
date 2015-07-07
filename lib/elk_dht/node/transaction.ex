defmodule ElkDHT.Node.Transaction do
  use GenServer
  require Logger
  alias ElkDHT.Utils
  @timeout 5
  def start_link(trans_id, timeout \\ @timeout, opts \\ []) do
    GenServer.start_link __MODULE__, [trans_id, timeout], opts ++ [timeout: timeout]
  end

  def init([trans_id, timeout]) do
    start_time = :calendar.local_time |> :calendar.datetime_to_gregorian_seconds
    Logger.debug "Transaction #{Hexate.encode(trans_id)} initialized."
    {:ok, {trans_id, start_time, timeout}, Utils.time_left(start_time, timeout)}
  end

  def id(pid) do
    GenServer.call pid, :id
  end

  def stop(pid) do
    GenServer.cast pid, :stop
  end

  def handle_call(:id, _from, {id, start_time, timeout}) do
    {:reply, id, {id, start_time}, Utils.time_left(start_time, timeout)}
  end

  def handle_cast(:stop, state) do
    {:stop, :normal, state}
  end

  def handle_info(:timeout, state = {id, _, timeout}) do
    Logger.debug "Transaction #{Hexate.encode(id)} timing out... timeout: #{timeout}"
    {:stop, :normal, state}
  end

  def terminate(_reason, _state) do
    :ok
  end
  
end
