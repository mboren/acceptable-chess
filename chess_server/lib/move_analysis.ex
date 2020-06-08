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
  @type rank :: String.t
  @type file :: :a | :b | :c | :d | :e | :f | :g | :h
  @type promo_to :: :q | :r | :b | :n


  def is_promotion?(piece, end_rank) do
    case {piece, end_rank} do
      {"P", "8"} -> true
      {"p", "1"} -> true
      _ -> false
    end
  end

  @spec is_enpassant?(piece, piece, file, file) :: boolean
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

  @spec is_straight_pawn_move(piece, file, file) :: boolean
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
