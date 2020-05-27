defmodule MoveRepresentation do
  @type square :: String.t
  @type move :: %{start: String.t, end: String.t} | %{start: String.t, end: String.t, promotion: promo_to}
  @type piece :: String.t
  @type rank :: String.t
  @type file :: :a | :b | :c | :d | :e | :f | :g | :h
  @type promo_to :: :q | :r | :b | :n

  @spec get_san(String.t(), [move], move) :: String.t()
  def get_san(fen, _legal_moves, %{start: start_square, end: end_square, promotion: promotion}) do
    {:ok, destination_piece} = get_piece_at_square(end_square, fen)

    {:ok, %{rank: _, file: start_file}} = get_rank_and_file(start_square)

    promo_string = promotion_to_string(promotion)
    if destination_piece == " " do
      "#{end_square}#{promo_string}"
    else
      "#{Atom.to_string(start_file)}x#{end_square}#{promo_string}"
    end
  end

  @spec promotion_to_string(promo_to) :: String.t
  def promotion_to_string(promo) do
    "=" <> String.upcase(Atom.to_string(promo))
  end

  def get_san(fen, legal_moves, move = %{start: start_square, end: end_square}) do
    piece_list = fen_to_piece_list(fen)
    {:ok, piece} = get_piece_at_square(start_square, fen)
    {:ok, destination_piece} = get_piece_at_square(end_square, fen)

    {:ok, %{rank: start_rank, file: start_file}} = get_rank_and_file(start_square)
    {:ok, %{rank: end_rank, file: end_file}} = get_rank_and_file(end_square)

    cond do
      is_straight_pawn_move(piece, start_file, end_file) -> end_square
      is_enpassant?(piece, destination_piece, start_file, end_file) -> Atom.to_string(start_file) <> "x" <> end_square
      is_pawn_capture?(piece, destination_piece) -> Atom.to_string(start_file) <> "x" <> end_square
      is_queenside_castle(piece, move) -> "O-O-O"
      is_kingside_castle(piece, move) -> "O-O"
      true ->
        context = get_disambiguation(piece, start_square, end_square, legal_moves, fen)
        if destination_piece != " " do
          String.upcase(piece) <> context <> "x" <> end_square
        else
          String.upcase(piece) <> context <> end_square
        end
    end
  end

  @spec is_enpassant?(piece, piece, file, file) :: boolean
  def is_enpassant?(piece, piece_at_destination, start_file, end_file) do
    is_pawn?(piece) and piece_at_destination == " " and start_file != end_file
  end

  @spec is_pawn_capture?(piece, piece) :: boolean
  def is_pawn_capture?(piece, piece_at_destination) do
    is_pawn?(piece) and piece_at_destination != " "
  end

  @spec get_moves_that_end_at(square, [move]) :: [move]
  def get_moves_that_end_at(square, moves) do
    moves
    |> Enum.filter(fn m -> get_move_end(m) == square end)
  end

  @spec get_move_end(move) :: square
  def get_move_end(%{end: e}) do
    e
  end

  @spec get_move_start(move) :: square
  def get_move_start(%{start: s}) do
    s
  end

  @spec get_move_context(piece, move, [move], String.t) :: [{:ok, map}]
  def get_move_context(piece, move = %{start: start_square, end: end_square}, legal_moves, fen) do
    moves = get_moves_that_end_at(end_square, legal_moves)
            |> MapSet.new()
            |> MapSet.delete(move)
            |> MapSet.to_list()

    moves
    |> Enum.map(&get_move_start/1)
    |> Enum.filter(fn s -> get_piece_at_square(s, fen) == {:ok, piece} end)
    |> Enum.map(&get_rank_and_file/1)
  end

  @spec get_disambiguation(piece, square, square, [move], String.t) :: String.t
  def get_disambiguation(piece, start_square, end_square, legal_moves, fen) do
    with {:ok, %{rank: start_rank, file: start_file}} <- get_rank_and_file(start_square) do

      potentially_ambiguous_squares = get_move_context(piece, %{start: start_square, end: end_square}, legal_moves, fen)
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

  @spec determine_context(file, rank, boolean, boolean) :: String.t
  def determine_context(start_file, start_rank, is_file_ambiguous, is_rank_ambiguous) do
    case {is_file_ambiguous, is_rank_ambiguous} do
      {false, _} -> Atom.to_string(start_file)
      {true, false} -> start_rank
      {true, true} -> to_string(start_file) <> start_rank
    end
  end

  def is_pawn?(piece) do
    case piece do
      "p" -> true
      "P" -> true
      _ -> false
    end
  end

  @spec get_rank_and_file(square) :: {:ok, %{rank: rank, file: file}} | {:error, any}
  def get_rank_and_file(square) do
    valid_ranks = MapSet.new(["1", "2", "3", "4", "5", "6", "7", "8"])

    case String.codepoints(square) do
      [file_string, rank] ->
        if MapSet.member?(valid_ranks, rank) do
          case file_from_string(file_string) do
            {:ok, file} ->
              {:ok, %{rank: rank, file: file}}
            {:error, message} ->
              {:error, message}
          end
        end
      _ ->
        {:error, "square string must have length 2"}
    end
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

  @spec get_piece_at_square(square, String.t) :: {:ok, piece} | {:error, any}
  def get_piece_at_square(square, fen) do
    piece_list = fen_to_piece_list(fen)
    with {:ok, index} <- square_to_index(square) do
      Enum.fetch(piece_list, index)
    end
  end



  @spec square_to_index(square) :: {:ok, 0..63} | {:error, any}
  def square_to_index(square) do
    with [file_string, rank] <- String.codepoints(square),
         {:ok, file} <- file_from_string(file_string),
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

  @spec file_from_string(String.t) :: {:ok, file} | {:error, any}
  def file_from_string(character) do
    case character do
      "a" -> {:ok, :a}
      "b" -> {:ok, :b}
      "c" -> {:ok, :c}
      "d" -> {:ok, :d}
      "e" -> {:ok, :e}
      "f" -> {:ok, :f}
      "g" -> {:ok, :g}
      "h" -> {:ok, :h}
      other -> {:error, other}
    end
  end

  @spec file_to_digit(file) :: {:ok, 1..8} | {:error, any}
  def file_to_digit(character) do
    case character do
      :a -> {:ok, 1}
      :b -> {:ok, 2}
      :c -> {:ok, 3}
      :d -> {:ok, 4}
      :e -> {:ok, 5}
      :f -> {:ok, 6}
      :g -> {:ok, 7}
      :h -> {:ok, 8}
      other -> {:error, other}
    end
  end
end
