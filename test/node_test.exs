defmodule ExDHTTest.Node do
  use ExUnit.Case
  alias ExDHT.Node, warn: false
  alias ExDHT.Utils, warn: false

  @trans_name "Trans"
  @trans_info_hash nil

  test "Can create node" do
    {:ok, _} = Node.start_link("localhost", 0, Utils.random_node_id)
  end

  test "Can add / remove transaction" do
    {:ok, node} = Node.start_link("localhost", 0, Utils.random_node_id)
    trans_id = Node.add_trans(node, @trans_name, @trans_info_hash)
    assert Node.delete_trans(node, trans_id) == :ok
  end
end
