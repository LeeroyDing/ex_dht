defmodule ElkDHT.Node.Store do
  @table __MODULE__

  def init, do: :ets.init_table @table, [:public, :named_table]

  def insert(key, value), do: :ets.insert @table, key, value

  def lookup(key) do
    case :ets.lookup @table, key do
      [{key, value}] -> {:ok, value}
      [] -> {:error, :not_found}
    end
  end

  def delete(key), do: :ets.delete key
end
