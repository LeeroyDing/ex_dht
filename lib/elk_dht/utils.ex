defmodule ElkDHT.Utils do
  @node_id_bits 160
  @trans_id_bits 32

  def random_node_id, do: :random.uniform(@node_id_bits / 8)
  def random_trans_code, do: :random.uniform(@trans_id_bits / 8)

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
end
