defmodule ChessAppTest do
  use ExUnit.Case
  doctest ChessApp

  test "greets the world" do
    assert ChessApp.hello() == :world
  end
end
