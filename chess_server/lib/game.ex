defmodule ChessApp.Game do
  defstruct(
    gameServer: nil,
    whitePlayer: nil,
    blackPlayer: nil,
    history: [],
    playerResigned: nil
  )
  @type player_id :: reference
  @type player_color :: :white | :black
  @type move :: %{start: String.t, end: String.t} | %{start: String.t, end: String.t, promotion: String.t}
  @type move_with_san :: %{san: String.t, start: String.t, end: String.t} | %{san: String.t, start: String.t, end: String.t, promotion: String.t}
  @type history :: list(move_with_san)

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

  @spec get_player_color(player_id, %ChessApp.Game{whitePlayer: player_id}) :: player_color
  def get_player_color(player_id, %ChessApp.Game{whitePlayer: player_id}) do
    :white
  end
  def get_player_color(player_id, %ChessApp.Game{blackPlayer: player_id}) do
    :black
  end

  @spec get_other_player_id(player_id, %ChessApp.Game{}) :: player_id
  def get_other_player_id(player_id, %ChessApp.Game{whitePlayer: player_id, blackPlayer: other_player_id}) do
    other_player_id
  end
  def get_other_player_id(player_id, %ChessApp.Game{whitePlayer: other_player_id, blackPlayer: player_id}) do
    other_player_id
  end

  def make_move(player_id, move, state = %ChessApp.Game{gameServer: pid, playerResigned: nil}) do
    {:ok, color_to_move} = :binbo.side_to_move(pid)
    player_color = get_player_color(player_id, state)
    {:ok, fen} = get_board_state(state)
    if color_to_move == player_color do
      add_move_to_history(:binbo.move(pid, move_map_to_string(move)), move_from_map(move), fen, state)
    else
      state
    end
  end

  def make_move(player_id, move, state = %ChessApp.Game{gameServer: pid, playerResigned: player}) do
    state
  end

  defp move_from_map(move) do
    case move do
      %{"start" => s, "end" => e, "promotion" => p} ->
        %{start: s, end: e, promotion: p}
      %{"start" => s, "end" => e} ->
         %{start: s, end: e}
      {s, e} -> %{start: s, end: e}
      {s, e, p} -> %{start: s, end: e, promotion: p}
    end
  end

  defp add_move_to_history({:ok, _}, move, fen, state = %ChessApp.Game{gameServer: pid}) do
    {:ok, legal_moves} =  :binbo.all_legal_moves(pid, :bin)
    legal_moves = Enum.map(legal_moves, &move_from_map/1)
    san = MoveRepresentation.get_san(fen, legal_moves, move)
    move_with_san = Map.put(move, :san, san)
    Map.put(state, :history, [move_with_san | state.history])
  end

  defp add_move_to_history({:error, _}, _move, state) do
    state
  end

  @spec get_board_state(%ChessApp.Game{}) :: :binbo_server.get_fen_ret()
  def get_board_state(%ChessApp.Game{gameServer: pid}) do
    :binbo.get_fen(pid)
  end

  def get_game_state(player_id, state = %ChessApp.Game{gameServer: pid, history: history}) do
    {:ok, fen} = :binbo.get_fen(pid)
    {:ok, legal_moves} =  :binbo.all_legal_moves(pid, :bin)
    {:ok, player_to_move} =  :binbo.side_to_move(pid)
    {:ok, status} =  get_game_status(state)
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

  defp get_game_status(%ChessApp.Game{gameServer: pid, playerResigned: nil}) do
    :binbo.game_status(pid)
  end

  defp get_game_status(%ChessApp.Game{gameServer: pid, playerResigned: player}) do
    {:ok, :resignation}
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

  @spec move_map_to_string(move) :: String.t
  defp move_map_to_string(%{"start" => s, "end" => e}) do
    s <> e
  end

  defp move_map_to_string(%{"start" => s, "end" => e, "promotion" => p}) do
    s <> e <> String.downcase(p)
  end
end
