defmodule Position do
  @moduledoc """
  Used for working with FEN formatted chess positions
  """
  @type piece :: String.t
  @type fen :: String.t
  @type piece_list :: [piece]

  @spec get_piece_at_square(Square.square, piece_list) :: {:ok, piece} | {:error, any}
  def get_piece_at_square(square, piece_list) do
    with {:ok, index} <- square_to_index(square) do
      Enum.fetch(piece_list, index)
    end
  end


  @spec square_to_index(Square.square) :: {:ok, 0..63} | {:error, any}
  def square_to_index(square) do
    with [file_string, rank] <- String.codepoints(square),
         {:ok, file} <- Square.file_from_string(file_string),
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


  @spec file_to_digit(Square.file) :: {:ok, 1..8} | {:error, any}
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
