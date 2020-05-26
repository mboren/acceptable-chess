defmodule MoveRepresentation do
  @type square :: String.t
  @type move :: {square, square}
  @type piece :: String.t
  @type rank :: String.t
  @type file :: String.t

  @spec get_san(String.t(), [move], move) :: String.t()
  def get_san(fen, legal_moves, {start_square, end_square}) do
    piece_list = fen_to_piece_list(fen)
    {:ok, piece} = get_piece_at_square(start_square, fen)
    {:ok, destination_piece} = get_piece_at_square(end_square, fen)

    {:ok, %{rank: start_rank, file: start_file}} = get_rank_and_file(start_square)
    {:ok, %{rank: end_rank, file: end_file}} = get_rank_and_file(end_square)

    cond do
      is_straight_pawn_move(piece, start_file, end_file) -> end_square
      is_queenside_castle(piece, {start_square, end_square}) -> "O-O-O"
      is_kingside_castle(piece, {start_square, end_square}) -> "O-O"
      true ->
        context = get_disambiguation(piece, start_square, end_square, legal_moves, fen)
        if destination_piece != " " do
          String.upcase(piece) <> context <> "x" <> end_square
        else
          String.upcase(piece) <> context <> end_square
        end
    end
  end

  @spec get_moves_that_end_at(square, [move]) :: [move]
  def get_moves_that_end_at(square, moves) do
    moves
    |> Enum.filter(fn {s, e} -> e == square end)
  end

  @spec get_move_context(piece, move, [move], String.t) :: [{:ok, map}]
  def get_move_context(piece, {start_square, end_square}, legal_moves, fen) do
    moves = get_moves_that_end_at(end_square, legal_moves)
        |> MapSet.new()
        |> MapSet.delete({start_square, end_square})
        |> MapSet.to_list()

    moves
      |> Enum.map(fn {s, e} -> s end)
      |> Enum.filter(fn s -> get_piece_at_square(s, fen) == {:ok, piece} end)
      |> Enum.map(&get_rank_and_file/1)
  end

  @spec get_disambiguation(piece, square, square, [move], String.t) :: String.t
  def get_disambiguation(piece, start_square, end_square, legal_moves, fen) do
    {:ok, %{rank: start_rank, file: start_file}} = get_rank_and_file(start_square)

    potentially_ambiguous_squares = get_move_context(piece, {start_square, end_square}, legal_moves, fen)
      |> Enum.filter(&match?({:ok, _}, &1))
      |> Enum.map(fn {:ok, rank_and_file} -> rank_and_file end)

    case potentially_ambiguous_squares do
      [] ->
        ""
      _ ->
        files = Enum.map(potentially_ambiguous_squares, fn %{rank: _, file: f} -> f end) |> MapSet.new
        ranks = Enum.map(potentially_ambiguous_squares, fn %{rank: r, file: _} -> r end) |> MapSet.new

        determine_context(start_file, start_rank, MapSet.member?(files, start_file), MapSet.member?(ranks, start_rank))
      end
  end

  def determine_context(start_file, start_rank, is_file_ambiguous = false, _is_rank_ambiguous) do
    start_file
  end

  def determine_context(start_file, start_rank, is_file_ambiguous = true, is_rank_ambiguous = false) do
    start_rank
  end

  def determine_context(start_file, start_rank, is_file_ambiguous = true, is_rank_ambiguous = true) do
    start_file <> start_rank
  end

  def is_pawn?(piece) do
    case piece do
      "p" -> true
      "P" -> true
      _ -> false
    end
  end

  @spec get_rank_and_file(square) :: {:ok, map}
  def get_rank_and_file(square) do
    valid_files = MapSet.new(["a", "b", "c", "d", "e", "f", "g", "h"])
    valid_ranks = MapSet.new(["1", "2", "3", "4", "5", "6", "7", "8"])

    with [file, rank] <- String.codepoints(square),
         true <- MapSet.member?(valid_files, file),
         true <- MapSet.member?(valid_ranks, rank) do
      {:ok, %{rank: rank, file: file}}
    end
  end

  @spec is_queenside_castle(piece, move) :: boolean
  def is_queenside_castle("K", {"e1", "c1"}) do
    true
  end

  def is_queenside_castle("k", {"e8", "c8"}) do
    true
  end

  def is_queenside_castle(_piece, {_start_square, _end_square}) do
    false
  end

  @spec is_kingside_castle(piece, move) :: boolean
  def is_kingside_castle("K", {"e1", "g1"}) do
    true
  end
  def is_kingside_castle("k", {"e8", "g8"}) do
    true
  end
  def is_kingside_castle(_piece, {_start_square, _end_square}) do
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

  @spec get_piece_at_square(square, String.t) :: {:ok, piece} | {:error, any}
  def get_piece_at_square(square, fen) do
    piece_list = fen_to_piece_list(fen)
    {:ok, index} = square_to_index(square)

    Enum.fetch(piece_list, index)
  end

  @spec square_to_index(square) :: {:ok, 0..63} | {:error, any}
  def square_to_index(square) do
    with [file, rank] <- String.codepoints(square),
         {:ok, file_num} <- file_to_digit(file),
         {:ok, rank_num} <- char_to_digit(rank)
      do
      {:ok, 63 - 8 * rank_num + file_num}
    else
      foo -> {:error, foo}
    end
  end

  @spec fen_to_piece_list(String.t()) :: [String.t()]
  def fen_to_piece_list(fen) do
    [pieces, _side_to_move, _castling, _enpassant, _halfmove, _fullmove] = String.split(fen, " ")

    rows = String.split(pieces, "/")
           |> Enum.map(&String.codepoints/1)
           |> Enum.map(fn pts -> Enum.map(pts, &digit_to_spaces/1) end)
           |> Enum.map(fn pts -> Enum.map(pts, &digit_to_spaces/1) end)
           |> List.flatten
    rows
  end

  def digit_to_spaces(character) do
    case char_to_digit(character) do
      {:ok, digit} ->
        List.duplicate(" ", digit)
      {:error, _} ->
        character
    end
  end

  @spec char_to_digit(String.t()) :: {:ok, 1..8} | {:error, any}
  def char_to_digit(character) do
    case character do
      "1" -> {:ok, 1}
      "2" -> {:ok, 2}
      "3" -> {:ok, 3}
      "4" -> {:ok, 4}
      "5" -> {:ok, 5}
      "6" -> {:ok, 6}
      "7" -> {:ok, 7}
      "8" -> {:ok, 8}
      other -> {:error, other}
    end
  end

  @spec file_to_digit(String.t()) :: {:ok, 1..8} | {:error, any}
  def file_to_digit(character) do
    case character do
      "a" -> {:ok, 1}
      "b" -> {:ok, 2}
      "c" -> {:ok, 3}
      "d" -> {:ok, 4}
      "e" -> {:ok, 5}
      "f" -> {:ok, 6}
      "g" -> {:ok, 7}
      "h" -> {:ok, 8}
      other -> {:error, other}
    end
  end
end
