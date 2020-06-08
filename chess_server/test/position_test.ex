defmodule PositionTest do
    use ExUnit.Case

    test "start position FEN to piece list" do
      start_fen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
      expected = ["r", "n", "b", "q", "k", "b", "n", "r", "p", "p", "p", "p", "p", "p", "p", "p", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", "P", "P", "P", "P", "P", "P", "P", "P", "R", "N", "B", "Q", "K", "B", "N", "R" ]
      assert Position.fen_to_piece_list(start_fen)  == expected
    end
    test "pawn move FEN to piece list" do
      fen = "rnbqkbnr/pppp1ppp/8/4p3/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
      expected = ["r", "n", "b", "q", "k", "b", "n", "r", "p", "p", "p", "p", " ", "p", "p", "p", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", "p", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", "P", "P", "P", "P", "P", "P", "P", "P", "R", "N", "B", "Q", "K", "B", "N", "R" ]
      assert Position.fen_to_piece_list(fen)  == expected
    end

    test "get piece at square for starting position" do
      fen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
      piece_list = Position.fen_to_piece_list(fen)
      assert Position.get_piece_at_square("a1", piece_list) == {:ok, "R"}
      assert Position.get_piece_at_square("a2", piece_list) == {:ok, "P"}
      assert Position.get_piece_at_square("a7", piece_list) == {:ok, "p"}
      assert Position.get_piece_at_square("a8", piece_list) == {:ok, "r"}
      assert Position.get_piece_at_square("a4", piece_list) == {:ok, " "}
      assert Position.get_piece_at_square("h2", piece_list) == {:ok, "P"}
    end
    test "get piece at square for more interesting position" do
      # B60 sicillian defence
      fen = "r1bqkb1r/pp2pppp/2np1n2/6B1/3NP3/2N5/PPP2PPP/R2QKB1R b KQkq - 5 6"
      piece_list = Position.fen_to_piece_list(fen)
      assert Position.get_piece_at_square("a1", piece_list) == {:ok, "R"}
      assert Position.get_piece_at_square("a2", piece_list) == {:ok, "P"}
      assert Position.get_piece_at_square("a7", piece_list) == {:ok, "p"}
      assert Position.get_piece_at_square("a8", piece_list) == {:ok, "r"}
      assert Position.get_piece_at_square("a4", piece_list) == {:ok, " "}
      assert Position.get_piece_at_square("h2", piece_list) == {:ok, "P"}
      assert Position.get_piece_at_square("e4", piece_list) == {:ok, "P"}
      assert Position.get_piece_at_square("d4", piece_list) == {:ok, "N"}
    end
end
