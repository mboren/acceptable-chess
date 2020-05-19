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

  def get_player_color(player_id, %ChessApp.Game{whitePlayer: player_id}) do
    :white
  end
  def get_player_color(player_id, %ChessApp.Game{blackPlayer: player_id}) do
    :black
  end

  def make_move(player_id, move, state = %ChessApp.Game{gameServer: pid}) do
    {:ok, color_to_move} = :binbo.side_to_move(pid)
    player_color = get_player_color(player_id, state)
    if color_to_move == player_color do
      :binbo.move(pid, move)
    else
      {:error, :wrong_player}
    end
  end


  def get_board_state(%ChessApp.Game{gameServer: pid}) do
    :binbo.get_fen(pid)
  end

  def get_game_state(player_id, state = %ChessApp.Game{gameServer: pid}) do
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
    }
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
end