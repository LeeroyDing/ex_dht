defmodule ElkDHT.Node do

  def create(host, port) do
    case ElkDHT.Supervisor.start_child(host, port) do
      {:ok, pid} -> {:ok, pid}
      other -> {:error, other}
    end
  end

  def find_node(node_pid) do
    {:ok, trans_pid} = ElkDHT.Node.Transaction.start_trans node_pid
    message = ElkDHT.Node.message :find_node
    ElkDHT.Node.Transaction.send_message trans_pid, message
  end
  
end
