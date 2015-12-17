defmodule ExDHTTest do
  use ExUnit.Case
  alias ExDHT.Utils, as: Utils

  test "the truth" do
    assert 1 + 1 == 2
  end

  test "message reaches the bootstrap node" do
    node_id = Utils.random_node_id
    message = %{"y" => "q", "q" => "find_node", "a" => %{"id" => node_id, "target" => node_id}}
    message = (message |> Map.put("t", Utils.random_trans_id) |> Map.put("v", Utils.get_version))
    encoded = Bencodex.encode message
    {:ok, sock} = :gen_udp.open 0, [:binary, {:active, false}]
    :gen_udp.send sock, 'router.bittorrent.com', 6881, [encoded]
    result = :gen_udp.recv sock, 0, 1000
    assert {:ok, _} = result
  end
end
