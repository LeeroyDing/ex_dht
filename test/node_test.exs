defmodule ExDHTTest.Node do
  use ExUnit.Case
  alias ExDHT.Node, warn: false
  alias ExDHT.Utils, warn: false

  @trans_name "Trans"
  @trans_info_hash nil
  @token_info_hash "token_info_hash"
  @token_value "123"

  test "Can create node" do
    {:ok, _} = Node.start_link("localhost", 0, Utils.random_node_id)
  end

  test "Can add / remove transaction" do
    {:ok, node} = Node.start_link("localhost", 0, Utils.random_node_id)
    trans_id = Node.add_trans(node, @trans_name, @trans_info_hash)
    assert Node.delete_trans(node, trans_id) == :ok
  end

  test "Can add / get / remove token" do
    {:ok, node} = Node.start_link("localhost", 0, Utils.random_node_id)
    assert Node.get_token(node, @token_info_hash) == nil
    assert Node.add_token(node, @token_info_hash, @token_value) == :ok
    assert Node.get_token(node, @token_info_hash) == @token_value
    assert Node.delete_token(node, @token_info_hash) == :ok
    assert Node.get_token(node, @token_info_hash) == nil
  end

  test "Can add / get / remove local token" do
    {:ok, node} = Node.start_link("localhost", 0, Utils.random_node_id)
    assert Node.get_local_token(node, @token_info_hash) == nil
    assert Node.add_local_token(node, @token_info_hash, @token_value) == :ok
    assert Node.get_local_token(node, @token_info_hash) == @token_value
    assert Node.delete_local_token(node, @token_info_hash) == :ok
    assert Node.get_local_token(node, @token_info_hash) == nil
  end
  
end
