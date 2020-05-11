defmodule ChessApp.Game.Interface do
  @moduledoc false

  def join_game(server, player_id) do
    GenServer.call(server, {:join_game, player_id})
  end

  def get_players(server) do
    GenServer.call(server, {:get_players})
  end

  def get_player_color(server, player_id) do
    GenServer.call(server, {:get_player_color, player_id})
  end

  def make_move(server, player_id, move) do
    GenServer.call(server, {:make_move, player_id, move})
  end

  def get_board_state(server) do
    GenServer.call(server, {:get_board_state})
  end
end
