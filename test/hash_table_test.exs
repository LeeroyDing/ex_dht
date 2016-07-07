defmodule ExDHTTest.HashTable do
  use ExUnit.Case
  alias ExDHT.HashTable, warn: false
  doctest HashTable

  @hash "abc"
  @peer "efg"

  setup do
    HashTable.start_link
    :ok
  end
  
  test "Can add / remove / check hash" do
    assert HashTable.has_hash?(@hash) == false
    HashTable.add_hash @hash
    assert HashTable.has_hash?(@hash) == true
    HashTable.remove_hash @hash
    assert HashTable.has_hash?(@hash) == false
  end

  test "Can add / remove / check peer for existing hash" do
    HashTable.add_hash @hash
    assert HashTable.has_peer?(@hash, @peer) == false
    HashTable.add_peer @hash, @peer
    assert HashTable.has_peer?(@hash, @peer) == true
    HashTable.remove_peer @hash, @peer
    assert HashTable.has_peer?(@hash, @peer) == false
    HashTable.remove_hash @hash
  end

  test "Can't add / remove / check peer for non-existing hash" do
    assert HashTable.add_peer(@hash, @peer) == :error
    assert HashTable.remove_peer(@hash, @peer) == :error
    assert HashTable.has_peer?(@hash, @peer) == :error
  end
  
end
