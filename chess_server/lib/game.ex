defmodule ChessApp.Game do
  defstruct(
    gameServer: nil,
    whitePlayer: nil,
    blackPlayer: nil,
    history: [],
    playerResigned: nil
  )

  def new_game() do
    {:ok, pid} = :binbo.new_server()
    :binbo.new_game(pid)
    %ChessApp.Game{gameServer: pid, history: []}
  end

  def resign(player_id, state = %ChessApp.Game{gameServer: pid, playerResigned: nil, whitePlayer: player_id}) do
    Map.put(state, :playerResigned, :white)
  end

  def resign(player_id, state = %ChessApp.Game{gameServer: pid, playerResigned: nil, blackPlayer: player_id}) do
    Map.put(state, :playerResigned, :black)
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

  def get_player_color(player_id, %ChessApp.Game{whitePlayer: player_id}) do
    :white
  end
  def get_player_color(player_id, %ChessApp.Game{blackPlayer: player_id}) do
    :black
  end

  def get_other_player_id(player_id, %ChessApp.Game{whitePlayer: player_id, blackPlayer: other_player_id}) do
    other_player_id
  end
  def get_other_player_id(player_id, %ChessApp.Game{whitePlayer: other_player_id, blackPlayer: player_id}) do
    other_player_id
  end

  def make_move(player_id, move, state = %ChessApp.Game{gameServer: pid, playerResigned: player}) do
    state
  end

  def make_move(player_id, move, state = %ChessApp.Game{gameServer: pid, playerResigned: nil}) do
    {:ok, color_to_move} = :binbo.side_to_move(pid)
    player_color = get_player_color(player_id, state)
    if color_to_move == player_color do
      add_move_to_history(:binbo.move(pid, move_map_to_string(move)), move, state)
    else
      state
    end
  end

  defp add_move_to_history({:ok, _}, move, state) do
    Map.put(state, :history, [move | state.history])
  end
  defp add_move_to_history({:error, _}, _move, state) do
    state
  end

  def get_board_state(%ChessApp.Game{gameServer: pid}) do
    :binbo.get_fen(pid)
  end

  def get_game_state(player_id, state = %ChessApp.Game{gameServer: pid, history: history}) do
    {:ok, fen} = :binbo.get_fen(pid)
    {:ok, legal_moves} =  :binbo.all_legal_moves(pid, :bin)
    {:ok, player_to_move} =  :binbo.side_to_move(pid)
    {:ok, status} =  :binbo.game_status(pid)
    player_color = get_player_color(player_id, state)

    %{board: fen,
      legal_moves: process_legal_moves(legal_moves),
      player_to_move: player_to_move,
      player_color: player_color,
      status: status,
      winner: get_winner(status, player_to_move, state),
      history: history,
    }
  end

  defp get_winner(:continue, _player_to_move, %ChessApp.Game{playerResigned: nil}) do
    nil
  end

  defp get_winner(:checkmate, player_to_move = :white, %ChessApp.Game{playerResigned: nil}) do
    :black
  end

  defp get_winner(:checkmate, player_to_move = :black, %ChessApp.Game{playerResigned: nil}) do
    :white
  end

  defp get_winner(_status, _player_to_move, %ChessApp.Game{playerResigned: :white}) do
    :black
  end

  defp get_winner(_status, _player_to_move, %ChessApp.Game{playerResigned: :black}) do
    :white
  end

  def process_legal_moves(moves) do
    Enum.map(moves, fn f ->  process_move(f) end)
  end

  def process_move({start, stop}) do
    %{start: start,
      end: stop
    }
  end
  def process_move({start, stop, promo}) do
    %{start: start,
      end: stop,
      promotion: promo,
    }
  end

  defp move_map_to_string(%{"start" => s, "end" => e}) do
    s <> e
  end
end
