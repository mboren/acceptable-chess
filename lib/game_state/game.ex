defmodule ChessApp.Game do
  @moduledoc """
  This module is responsible for managing the state for a single chess game.
  Most of the board state is kept by a binbo process that we store a reference to in game_server.
  However, binbo doesn't provide functions to get past moves that were made, or pieces that were
  captured, so we store those in this module.
  This module also keeps track of connected players
  """
  defstruct(
    game_server: nil,
    white_player: nil,
    black_player: nil,
    history: [],
    player_resigned: nil,
    black_captured_pieces: [],
    white_captured_pieces: []
  )
  @type player_id :: reference | :nil
  @type player_color :: :white | :black
  @type move :: %{start: String.t, end: String.t} | %{start: String.t, end: String.t, promotion: String.t}
  @type move_with_san :: %{san: String.t, start: String.t, end: String.t} | %{san: String.t, start: String.t, end: String.t, promotion: String.t}
  @type history :: list(move_with_san)

  def new_game() do
    {:ok, pid} = :binbo.new_server()
    :binbo.new_game(pid)
    %ChessApp.Game{game_server: pid, history: []}
  end

  def restart_game(state = %ChessApp.Game{game_server: pid}) do
    :binbo.new_game(pid)
    state
      |> Map.put(:history, [])
      |> Map.put(:player_resigned, nil)
      |> Map.put(:black_captured_pieces, [])
      |> Map.put(:white_captured_pieces, [])
  end

  def resign(player_id, state = %ChessApp.Game{player_resigned: nil, white_player: player_id}) do
    Map.put(state, :player_resigned, :white)
  end

  def resign(player_id, state = %ChessApp.Game{player_resigned: nil, black_player: player_id}) do
    Map.put(state, :player_resigned, :black)
  end

  def add_player_to_game(player_id, state = %ChessApp.Game{white_player: nil, black_player: _player}) do
    Map.put(state, :white_player, player_id)
  end

  def add_player_to_game(player_id, state = %ChessApp.Game{white_player: _player, black_player: nil}) do
    Map.put(state, :black_player, player_id)
  end
  def add_player_to_game(_player_id, state = %ChessApp.Game{white_player: _player, black_player: _player2}) do
    # if both players have already been set, don't do anything
    state
  end

  @spec get_player_color(player_id, %ChessApp.Game{white_player: player_id}) :: player_color
  def get_player_color(player_id, %ChessApp.Game{white_player: player_id}) do
    :white
  end
  def get_player_color(player_id, %ChessApp.Game{black_player: player_id}) do
    :black
  end

  @spec get_other_player_id(player_id, %ChessApp.Game{}) :: player_id
  def get_other_player_id(player_id, %ChessApp.Game{white_player: player_id, black_player: other_player_id}) do
    other_player_id
  end
  def get_other_player_id(player_id, %ChessApp.Game{white_player: other_player_id, black_player: player_id}) do
    other_player_id
  end

  @spec make_move(player_id, move, %ChessApp.Game{}) :: %ChessApp.Game{}
  def make_move(player_id, move, state = %ChessApp.Game{game_server: pid, player_resigned: nil}) do
    {:ok, color_to_move} = :binbo.side_to_move(pid)
    player_color = get_player_color(player_id, state)
    {:ok, fen} = get_board_state(state)
    if color_to_move == player_color do
      move_result = :binbo.move(pid, move_map_to_string(move))
      case move_result do
        {:ok, _status} ->
          add_move_to_history(move_from_map(move), fen, state)
            |> add_captured_piece(player_color, move, fen)
        {:error, _err} ->
          state
      end
    else
      state
    end
  end

  def make_move(_player_id, _move, state = %ChessApp.Game{game_server: _pid, player_resigned: _player}) do
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

  defp add_move_to_history(move, fen, state = %ChessApp.Game{game_server: pid}) do
    {:ok, legal_moves} =  :binbo.all_legal_moves(pid, :bin)
    legal_moves = Enum.map(legal_moves, &move_from_map/1)
    san = MoveRepresentation.get_san(fen, legal_moves, move)
    move_with_san = Map.put(move, :san, san)
    Map.put(state, :history, [move_with_san | state.history])
  end

  defp add_captured_piece(state, player_to_move, move, fen) do
    move = move_from_map(move)
    captured_piece = MoveAnalysis.get_captured_piece(move, fen)
    case captured_piece do
      nil -> state
      piece ->
        case player_to_move do
          :white ->
            Map.put(state, :black_captured_pieces, [piece | state.black_captured_pieces])
          :black ->
            Map.put(state, :white_captured_pieces, [piece | state.white_captured_pieces])
        end
    end
  end


  @spec get_board_state(%ChessApp.Game{}) :: :binbo_server.get_fen_ret()
  def get_board_state(%ChessApp.Game{game_server: pid}) do
    :binbo.get_fen(pid)
  end

  def get_game_state(player_id, state = %ChessApp.Game{game_server: pid, history: history}) do
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
      black_captured_pieces: state.black_captured_pieces,
      white_captured_pieces: state.white_captured_pieces,
      both_players_connected: have_both_players_connected?(state),
    }
  end

  @spec have_both_players_connected?(%ChessApp.Game{white_player: player_id, black_player: player_id}) :: bool
  defp have_both_players_connected?(%ChessApp.Game{white_player: white, black_player: black}) do
    not is_nil(white) and not is_nil(black)
  end

  defp get_game_status(%ChessApp.Game{game_server: pid, player_resigned: nil}) do
    :binbo.game_status(pid)
  end

  defp get_game_status(%ChessApp.Game{player_resigned: _player}) do
    {:ok, :resignation}
  end

  defp get_winner(:continue, _player_to_move, %ChessApp.Game{player_resigned: nil}) do
    nil
  end

  defp get_winner(:checkmate, _player_to_move = :white, %ChessApp.Game{player_resigned: nil}) do
    :black
  end

  defp get_winner(:checkmate, _player_to_move = :black, %ChessApp.Game{player_resigned: nil}) do
    :white
  end

  defp get_winner(_status, _player_to_move, %ChessApp.Game{player_resigned: :white}) do
    :black
  end

  defp get_winner(_status, _player_to_move, %ChessApp.Game{player_resigned: :black}) do
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
  defp move_map_to_string(%{"start" => s, "end" => e, "promotion" => nil}) do
    s <> e
  end

  defp move_map_to_string(%{"start" => s, "end" => e, "promotion" => p}) do
    s <> e <> String.downcase(p)
  end
end
