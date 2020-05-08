defmodule ChessApp.Game do
  defstruct(
    gameServer: nil,
    whitePlayer: nil,
    blackPlayer: nil
  )

  def new_game() do
    {:ok, pid} = :binbo.new_server()
    :binbo.new_game(pid)
    %ChessApp.Game{gameServer: pid}
  end

  def add_player_to_game(player_id, state = %ChessApp.Game{gameServer: _pid, whitePlayer: nil, blackPlayer: _player}) do
    Map.put(state, :whitePlayer, player_id)
  end

  def add_player_to_game(player_id, state = %ChessApp.Game{gameServer: _pid, whitePlayer: _player, blackPlayer: nil}) do
    Map.put(state, :blackPlayer, player_id)
  end
  def add_player_to_game(_player_id, state = %ChessApp.Game{gameServer: _pid, whitePlayer: _player, blackPlayer: _player2}) do
    # if both players have already been set, don't do anything
    state
  end
end