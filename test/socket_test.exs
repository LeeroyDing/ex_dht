defmodule ExDHTTest.Socket do
  use ExUnit.Case
  alias ExDHT.Socket, warn: false
  doctest ExDHT.Socket

  @test_message "Yo"

  defmodule EventBouncer do
    use GenEvent
    def handle_event(event, parent) do
      send parent, event
      {:ok, parent}
    end
  end

  setup_all do
    Socket.start_link
    :ok
  end

  test "Can receive message" do
    {:ok, client} = :gen_udp.open 0
    {:ok, client_port} = :inet.port(client)
    Socket.add_handler EventBouncer, self
    :gen_udp.send client, 'localhost', Socket.port, @test_message
    assert_receive {{127, 0, 0, 1}, ^client_port, @test_message}
    Socket.remove_handler EventBouncer
  end

  test "Won't receive message when removed" do
    {:ok, client} = :gen_udp.open 0
    {:ok, client_port} = :inet.port client
    Socket.add_handler EventBouncer, self
    Socket.remove_handler EventBouncer
    :gen_udp.send client, 'localhost', Socket.port, @test_message
    refute_receive {{127, 0, 0, 1}, ^client_port, @test_message}
  end

  test "Can send message" do
    {:ok, server} = :gen_udp.open(0, [:binary, {:active, true}])
    {:ok, server_port} = :inet.port server
    client_port = Socket.port
    Socket.send_message(@test_message, "localhost", server_port)
    assert_receive {:udp, ^server, {127, 0, 0, 1}, ^client_port, @test_message}
  end
  
end
