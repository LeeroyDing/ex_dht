defmodule ExDHTTest.Utils do
  use ExUnit.Case
  alias ExDHT.Utils, warn: false

  def ip do
    ["0.0.0.1", "0.0.1.0", "0.0.1.1", "0.1.0.0", "0.1.0.1", "0.1.1.0", "0.1.1.1", "1.0.0.0",
     "1.0.0.1", "1.0.1.0", "1.0.1.1", "1.1.0.0", "1.1.0.1", "1.1.1.0", "1.1.1.1",
     "127.0.0.1", "127.0.0.2", "192.168.0.1", "192.168.1.1", "172.16.73.173", "10.9.54.17"]
  end

  def hex do
    ["00000001", "00000100", "00000101", "00010000", "00010001", "00010100", "00010101", "01000000",
     "01000001", "01000100", "01000101", "01010000", "01010001", "01010100", "01010101",
     "7F000001", "7F000002", "C0A80001", "C0A80101", "AC1049AD", "0A093611"]
  end

  test "change from ip to hex" do
    result = Enum.map ip, &(Utils.ip_to_hex(&1))
    assert length(result) == length(hex)
    Enum.zip(result, hex)
    |> Enum.each(fn {lhs, rhs} ->
      assert lhs == rhs
    end)
  end

  test "change from hex to ip" do
    result = Enum.map hex, &(Utils.hex_to_ip(&1))
    assert length(result) == length(ip)
    Enum.zip(result, ip)
    |> Enum.each(fn {lhs, rhs} ->
      assert lhs == rhs
    end)
  end

  test "BT version" do
    assert Utils.version == "BT\x00\x01"
  end
end
