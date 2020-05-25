defmodule MoveRepresentation do
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
        if destination_piece != " " do
          String.upcase(piece) <> "x" <> end_square
        else
          String.upcase(piece) <> end_square
        end
    end
  end

  def get_moves_that_end_at(square, moves) do
    moves
    |> Enum.filter(fn {s, e} -> e == square end)
  end

  def get_move_context(piece, {start_square, end_square}, legal_moves, fen) do
    squares_to_disambiguate =
      get_moves_that_end_at(end_square)
      |> Enum.map (fn {s, e} -> s end)
      |> Enum.filter (fn s -> get_piece_at_square(s, fen) == piece end)
      |> Enum.map(&get_rank_and_file/1)
  end

  def isPawn?(piece) do
    case piece do
      "p" -> true
      "P" -> true
      _ -> false
    end
  end

  def get_rank_and_file(square) do
    valid_files = MapSet.new(["a", "b", "c", "d", "e", "f", "g", "h"])
    valid_ranks = MapSet.new(["1", "2", "3", "4", "5", "6", "7", "8"])

    with [file, rank] <- String.codepoints(square),
         true <- MapSet.member?(valid_files, file),
         true <- MapSet.member?(valid_ranks, rank) do
      {:ok, %{rank: rank, file: file}}
    end
  end
  def is_queenside_castle("K", {"e1", "c1"}) do
    true
  end
  def is_queenside_castle("k", {"e8", "c8"}) do
    true
  end
  def is_queenside_castle(_piece, {_start_square, _end_square}) do
    false
  end
  def is_kingside_castle("K", {"e1", "g1"}) do
    true
  end
  def is_kingside_castle("k", {"e8", "g8"}) do
    true
  end
  def is_kingside_castle(_piece, {_start_square, _end_square}) do
    false
  end

  def is_straight_pawn_move("p", start_file, end_file) when start_file == end_file do
    true
  end
  def is_straight_pawn_move("P", start_file, end_file) when start_file == end_file do
    true
  end
  def is_straight_pawn_move(piece, start_file, end_file) do
    false
  end

  def get_piece_at_square(square, fen) do
    piece_list = fen_to_piece_list(fen)
    {:ok, index} = square_to_index(square)

    Enum.fetch(piece_list, index)
  end

  def square_to_index(square) do
    with [file, rank] <- String.codepoints(square),
         {:ok, fileNum} <- file_to_digit(file),
         {:ok, rankNum} <- char_to_digit(rank)
      do
      {:ok, 63 - 8 * rankNum + fileNum}
    else
      foo -> {:error, foo}
    end
  end

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
