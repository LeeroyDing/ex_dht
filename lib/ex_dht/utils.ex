defmodule ExDHT.Utils do
  use Bitwise

  @node_id_bits 160
  @trans_id_bits 32

  def seed do
    :rand.seed(:exsplus)
  end
  
  def random_node_id do
    @node_id_bits |> div(8) |> random_bytes
  end

  def random_trans_id do
    @trans_id_bits |> div(8) |> random_bytes
  end

  defp random_bytes(n) when is_number(n) do
    List.duplicate(0, n) |> Enum.map(fn _ -> :rand.uniform(256) - 1 end) |> Enum.reduce(<<>>, fn x, acc -> acc <> <<x>> end)
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

  def time_left(start_time, timeout) do
    now = :calendar.local_time
    current_time = now |> :calendar.datetime_to_gregorian_seconds
    time_elapsed = current_time - start_time
    case timeout - time_elapsed do
      time when time <= 0 -> 0
      time -> time * 1000
    end
  end

  def parse_nodes(raw_nodes) do
    raw_nodes
    |> parse_nodes([])
  end

  defp parse_nodes(<<>>, nodes) when is_list(nodes), do: Enum.reverse(nodes)

  defp parse_nodes(raw_nodes, nodes) when is_list(nodes) do
    <<_data :: size(208), _ :: binary>> = raw_nodes
    <<node_id :: @node_id_bits, ip :: size(32), port :: size(16), rest :: binary>> = raw_nodes
    <<a, b, c, d>> = <<ip :: size(32)>>

    parse_nodes(rest, [{<<node_id :: @node_id_bits>>, "#{a}.#{b}.#{c}.#{d}", port} | nodes])
  end

  def string_xor(lhs, rhs) do
    Enum.zip(to_charlist(lhs), to_charlist(rhs))
    |> Enum.map(fn {x, y} -> x ^^^ y end)
    |> to_string
  end

  def version do
    "BT\x00\x01"
  end
end
