defmodule MoveRepresentation do
  @moduledoc """
  This module is used to convert moves to the Standard Algebraic Notation (SAN) format for display to the user
  https://en.wikipedia.org/wiki/Algebraic_notation_(chess)
  """
  alias MoveAnalysis, as: MA
  @type square :: String.t
  @type move :: %{start: String.t, end: String.t} | %{start: String.t, end: String.t, promotion: String.t | nil}
  @type piece :: String.t

  @spec get_san(String.t(), [move], move) :: String.t()
  def get_san(fen, legal_moves, move = %{start: start_square, end: end_square, promotion: nil}) do
    piece_list = Position.fen_to_piece_list(fen)
    {:ok, piece} = Position.get_piece_at_square(start_square, piece_list)
    {:ok, destination_piece} = Position.get_piece_at_square(end_square, piece_list)

    {:ok, %{rank: _start_rank, file: start_file}} = Square.get_rank_and_file(start_square)
    {:ok, %{rank: end_rank, file: end_file}} = Square.get_rank_and_file(end_square)

    # if a pawn ends up at the end of the board, but we no promotion is stated,
    # binbo will automatically make it a queen
    implicit_promotion =
      if MA.is_promotion?(piece, end_rank) do
        "=Q"
      else
        ""
      end

    cond do
      MA.is_straight_pawn_move(piece, start_file, end_file) -> end_square <> implicit_promotion
      MA.is_enpassant?(piece, destination_piece, start_file, end_file) -> Atom.to_string(start_file) <> "x" <> end_square
      MA.is_pawn_capture?(piece, destination_piece) -> Atom.to_string(start_file) <> "x" <> end_square <> implicit_promotion
      MA.is_queenside_castle(piece, move) -> "O-O-O"
      MA.is_kingside_castle(piece, move) -> "O-O"
      true ->
        context = get_disambiguation(piece, start_square, end_square, legal_moves, piece_list)
        if destination_piece != " " do
          String.upcase(piece) <> context <> "x" <> end_square
        else
          String.upcase(piece) <> context <> end_square
        end
    end
  end

  def get_san(fen, _legal_moves, %{start: start_square, end: end_square, promotion: promotion}) do
    piece_list = Position.fen_to_piece_list(fen)
    {:ok, destination_piece} = Position.get_piece_at_square(end_square, piece_list)

    {:ok, %{rank: _, file: start_file}} = Square.get_rank_and_file(start_square)

    promo_string = promotion_to_string(promotion)
    if destination_piece == " " do
      "#{end_square}#{promo_string}"
    else
      "#{Atom.to_string(start_file)}x#{end_square}#{promo_string}"
    end
  end

  @spec promotion_to_string(String.t) :: String.t
  def promotion_to_string(promo) do
    "=" <> String.upcase(promo)
  end


  @spec get_moves_that_end_at(square, [move]) :: [move]
  def get_moves_that_end_at(square, moves) do
    moves
    |> Enum.filter(fn m -> MA.get_move_end(m) == square end)
  end

  @spec get_move_context(piece, move, [move], Position.piece_list) :: [{:ok, map}]
  def get_move_context(piece, move = %{start: _start_square, end: end_square}, legal_moves, piece_list) do
    moves = get_moves_that_end_at(end_square, legal_moves)
            |> MapSet.new()
            |> MapSet.delete(move)
            |> MapSet.to_list()

    moves
    |> Enum.map(&MA.get_move_start/1)
    |> Enum.filter(fn s -> Position.get_piece_at_square(s, piece_list) == {:ok, piece} end)
    |> Enum.map(&Square.get_rank_and_file/1)
  end

  @spec get_disambiguation(piece, square, square, [move], Position.piece_list) :: String.t
  def get_disambiguation(piece, start_square, end_square, legal_moves, piece_list) do
    with {:ok, %{rank: start_rank, file: start_file}} <- Square.get_rank_and_file(start_square) do

      potentially_ambiguous_squares = get_move_context(piece, %{start: start_square, end: end_square}, legal_moves, piece_list)
                                      |> Enum.filter(&match?({:ok, _}, &1))
                                      |> Enum.map(fn {:ok, rank_and_file} -> rank_and_file end)

      case potentially_ambiguous_squares do
        [] ->
          ""
        _ ->
          files = Enum.map(potentially_ambiguous_squares, fn %{rank: _, file: f} -> f end)
                  |> MapSet.new
          ranks = Enum.map(potentially_ambiguous_squares, fn %{rank: r, file: _} -> r end)
                  |> MapSet.new

          determine_context(start_file, start_rank, MapSet.member?(files, start_file), MapSet.member?(ranks, start_rank))
      end
    else
      _ -> ""
    end
  end

  @spec determine_context(Square.file, Square.rank, boolean, boolean) :: String.t
  def determine_context(start_file, start_rank, is_file_ambiguous, is_rank_ambiguous) do
    case {is_file_ambiguous, is_rank_ambiguous} do
      {false, _} -> Atom.to_string(start_file)
      {true, false} -> start_rank
      {true, true} -> to_string(start_file) <> start_rank
    end
  end
end
