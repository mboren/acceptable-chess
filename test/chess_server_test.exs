defmodule ChessServerTest do
  use ExUnit.Case
  doctest ChessServer

  test "greets the world" do
    assert ChessServer.hello() == :world
  end
end
