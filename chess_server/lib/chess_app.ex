defmodule ChessApp do
  @moduledoc """
  Documentation for `ChessApp`.
  """

  use Application


  def start(_type, _arg) do
    children = [{Registry, keys: :unique, name: ChessApp.Registry}]
    Supervisor.start_link(children, strategy: :one_for_one)
  end

  def get_player_id() do
    make_ref()
  end

  def create_game() do
    game_id = make_ref()
    GenServer.start_link(ChessApp.Game.Server, [], name: {:via, Registry, {ChessApp.Registry, game_id}})
    game_id
  end

  def join_game(game_id, player_id) do
    [{pid, _}] = Registry.lookup(ChessApp.Registry, game_id)
    ChessApp.Game.Interface.join_game(pid, player_id)
  end

  def make_move(game_id, player_id, move) do
    [{pid, _}] = Registry.lookup(ChessApp.Registry, game_id)
    ChessApp.Game.Interface.make_move(pid, player_id, move)
  end
  def get_board_state(game_id) do
    [{pid, _}] = Registry.lookup(ChessApp.Registry, game_id)
    ChessApp.Game.Interface.get_board_state(pid)
  end

  def get_game_state(game_id, player_id) do
    [{pid, _}] = Registry.lookup(ChessApp.Registry, game_id)
    ChessApp.Game.Interface.get_game_state(pid, player_id)
  end
end
