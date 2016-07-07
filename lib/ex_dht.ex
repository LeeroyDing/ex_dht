defmodule ExDHT do
  use Application
  require Logger
  
  @max_bootstrap_attempts 5
  @bootstrap_target_nodes 16
  @bootstrap_attemp_timeout 10000

  def start(_type, _args) do
    {:ok, self}
  end

  def stop(_state) do
    {:ok}
  end

end
