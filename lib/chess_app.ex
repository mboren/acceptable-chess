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
end
