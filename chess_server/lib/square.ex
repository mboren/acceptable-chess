defmodule Square do
  @moduledoc false
  @type square :: String.t
  @type rank :: String.t
  @type file :: :a | :b | :c | :d | :e | :f | :g | :h

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
end
