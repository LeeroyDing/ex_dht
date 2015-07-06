defmodule ElkDHT.Node.Transaction do
  require Logger
  
  def send_message(message, node_pid) do
    {:ok, trans_pid} = ElkDHT.Node.Transaction.Supervisor.start_child node_pid
    ElkDHT.Node.Transaction.Worker.send_message trans_pid, message
  end
end
