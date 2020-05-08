defmodule ChessApp.Game.Interface do
  @moduledoc false

  def join_game(server, player_id) do
    GenServer.call(server, {:join_game, player_id})
  end

  def get_players(server) do
    GenServer.call(server, {:get_players})
  end
end
