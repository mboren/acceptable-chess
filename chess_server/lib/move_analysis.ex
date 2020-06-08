defmodule MoveAnalysis do
  @moduledoc """
  This module is used to get additional information about the game that the chess
  library we're using (binbo) doesn't share.
  For example, was there a capture? did a promotion happen implicitly? was there an en passant move?
  This is mostly used for displaying moves in SAN format.
  """
  @type square :: String.t
  @type move :: %{start: String.t, end: String.t} | %{start: String.t, end: String.t, promotion: promo_to}
  @type piece :: String.t
  @type promo_to :: :q | :r | :b | :n



  @spec get_captured_piece(move, Position.fen) :: piece | nil
  def get_captured_piece(move, fen) do
    piece_list = Position.fen_to_piece_list(fen)
    start_square = get_move_start(move)
    end_square = get_move_end(move)
    {:ok, piece_at_start} = Position.get_piece_at_square(start_square, piece_list)
    {:ok, piece_at_end} = Position.get_piece_at_square(end_square, piece_list)
    {:ok, %{rank: _, file: start_file}} = Square.get_rank_and_file(start_square)
    {:ok, %{rank: _, file: end_file}} = Square.get_rank_and_file(end_square)
    cond do
      piece_at_end != " " -> piece_at_end
      is_enpassant?(piece_at_start, piece_at_end, start_file, end_file) ->
        case piece_at_start do
          "p" -> "P"
          "P" -> "p"
        end
      true -> nil
    end
  end

  def is_promotion?(piece, end_rank) do
    case {piece, end_rank} do
      {"P", "8"} -> true
      {"p", "1"} -> true
      _ -> false
    end
  end

  @spec is_enpassant?(piece, piece, Square.file, Square.file) :: boolean
  def is_enpassant?(piece, piece_at_destination, start_file, end_file) do
    is_pawn?(piece) and piece_at_destination == " " and start_file != end_file
  end

  def is_pawn?(piece) do
    case piece do
      "p" -> true
      "P" -> true
      _ -> false
    end
  end

  @spec is_pawn_capture?(piece, piece) :: boolean
  def is_pawn_capture?(piece, piece_at_destination) do
    is_pawn?(piece) and piece_at_destination != " "
  end


  @spec is_queenside_castle(piece, move) :: boolean
  def is_queenside_castle("K", %{start: "e1", end: "c1"}) do
    true
  end

  def is_queenside_castle("k", %{start: "e8", end: "c8"}) do
    true
  end

  def is_queenside_castle(_piece, _move) do
    false
  end

  @spec is_kingside_castle(piece, move) :: boolean
  def is_kingside_castle("K", %{start: "e1", end: "g1"}) do
    true
  end
  def is_kingside_castle("k", %{start: "e8", end: "g8"}) do
    true
  end
  def is_kingside_castle(_piece, _move) do
    false
  end

  @spec is_straight_pawn_move(piece, Square.file, Square.file) :: boolean
  def is_straight_pawn_move("p", start_file, end_file) when start_file == end_file do
    true
  end
  def is_straight_pawn_move("P", start_file, end_file) when start_file == end_file do
    true
  end
  def is_straight_pawn_move(piece, start_file, end_file) do
    false
  end

  @spec get_move_end(move) :: square
  def get_move_end(%{end: e}) do
    e
  end

  @spec get_move_start(move) :: square
  def get_move_start(%{start: s}) do
    s
  end
end
