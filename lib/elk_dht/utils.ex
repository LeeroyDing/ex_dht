defmodule ElkDHT.Utils do
  import Bitwise
  @node_id_bits 160
  @trans_id_bits 32

  def random_node_id do
    node_id = (1 <<< @node_id_bits |> :random.uniform)
    << node_id :: size(@node_id_bits) >>
  end
  
  def random_trans_id do
    trans_id = (1 <<< @trans_id_bits |> :random.uniform)
    << trans_id :: size(@trans_id_bits) >>
  end

  def ip_to_hex(ip) do
    ip
    |> String.split(".")
    |> Enum.reduce("", fn x, acc ->
      x_hex = :io_lib.fwrite('~2.16.0B', [String.to_integer(x)]) |> to_string
      acc <> x_hex
    end)
  end

  def hex_to_ip(hex) do
    hex |> to_char_list |> Enum.chunk(2)  # [["1", "F"], ["0", "B"], ...]
    |> Enum.map(fn [l, r] ->
      l = <<l>> |> String.to_integer(16)
      r = <<r>> |> String.to_integer(16)
      l * 16 + r
    end)
    |> Enum.map_join(".", &(Integer.to_string(&1)))
  end

  def get_version do
    "BT\x00\x01"
  end
end
