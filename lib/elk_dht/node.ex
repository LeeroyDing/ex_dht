defmodule ElkDHT.Node do

  def create(host, port) do
    case ElkDHT.Supervisor.start_child(host, port) do
      {:ok, pid} -> {:ok, pid}
      other -> {:error, other}
    end
  end

  def find_node(node_pid) do
    message = message node_pid, :find_node
    ElkDHT.Node.Transaction.send_message message, node_pid
  end

  def message(node_pid, :find_node) do
    ElkDHT.Node.Worker.message node_pid, :find_node
  end

  def socket(sup_pid) do
    :not_implemented
  end

end
