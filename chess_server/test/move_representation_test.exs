defmodule MoveRepresentationTest do
  use ExUnit.Case

  alias MoveRepresentation, as: MR

  @moduletag :capture_log

  doctest MoveRepresentation

  test "module exists" do
    assert is_list(MoveRepresentation.module_info())
  end

  test "pawn capture" do
    fen = "rnbqkbnr/ppp1pppp/3p4/4P3/8/8/PPPP1PPP/RNBQKBNR w KQkq - 0 1"
    legal_move = {"d6", "e5"}
    assert MR.get_san(fen, [legal_move], legal_move) == "dxe5"
  end

  test "white pawn promotion" do
    fen = "rnbqkbn1/pppppppP/8/8/8/8/PPPPPPP1/RNBQKBNR w KQq - 0 1"
    legal_moves = [{"h7", "h8", "N"} , {"h7", "h8", "Q"}, {"h7", "h8", "R"}, {"h7", "h8", "B"}, {"h7", "g8", "N"}, {"h7", "g8", "Q"}, {"h7", "g8", "R"}, {"h7", "g8", "B"}]
    assert MR.get_san(fen, legal_moves, {"h7", "h8", "N"}) == "h8=N"
    assert MR.get_san(fen, legal_moves, {"h7", "g8", "Q"}) == "hxg8=Q"
  end

  test "black pawn promotion" do
    fen = "rnbqkbnr/ppppppp1/8/8/8/8/PPPPPPPp/RNBQKB2 b Qkq - 0 1"
    legal_moves = [{"h2", "h1", "N"} , {"h2", "h1", "Q"} , {"h2", "h1", "R"} , {"h2", "h1", "B"}]
    assert MR.get_san(fen, legal_moves, {"h2", "h1", "N"}) == "h1=N"
    assert MR.get_san(fen, legal_moves, {"h2", "h1", "R"}) == "h1=R"
    assert MR.get_san(fen, legal_moves, {"h2", "h1", "B"}) == "h1=B"
    assert MR.get_san(fen, legal_moves, {"h2", "h1", "Q"}) == "h1=Q"
  end

  test "get_san" do
    start_fen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
    legal_moves = [{"h2", "h4"}, {"h2", "h3"}, {"g2", "g4"}, {"g2", "g3"}, {"f2", "f4"}, {"f2", "f3"}, {"e2", "e4"}, {"e2", "e3"}, {"d2", "d4"}, {"d2", "d3"}, {"c2", "c4"}, {"c2", "c3"}, {"b2", "b4"}, {"b2", "b3"}, {"a2", "a4"}, {"a2", "a3"}, {"g1", "h3"}, {"g1", "f3"}, {"b1", "c3"}, {"b1", "a3"}]
    result = MR.get_san(start_fen, legal_moves, Enum.at(legal_moves, 0))
    assert result == "h4"
    assert MR.get_san(start_fen, legal_moves, {"b1", "c3"}) == "Nc3"
  end

  test "castling san" do
    fen = "r1bqk1nr/pp1n1pbp/2p1p1p1/3p4/3P1B2/2NQ1NP1/PPP1PPBP/R3K2R w KQkq - 0 1"
    white_kingside_castle = {"e1", "g1"}
    white_queenside_castle = {"e1", "c1"}
    legal_moves = [white_kingside_castle, white_queenside_castle]

    assert MR.get_san(fen, legal_moves, white_kingside_castle ) == "O-O"
    assert MR.get_san(fen, legal_moves, white_queenside_castle ) == "O-O-O"
  end

  test "capture san" do
    fen = "rnbqkbnr/ppp1pppp/8/3p4/8/2N5/PPPPPPPP/R1BQKBNR w KQkq - 0 1"
    knight_capture = {"c3", "d5"}
    legal_moves = [knight_capture]

    assert MR.get_san(fen, legal_moves, knight_capture) == "Nxd5"
  end

  test "ambiguous san knight move" do
    fen = "rnbqkbnr/ppp2ppp/4p3/3p4/3N4/2N5/PPPPPPPP/R1BQKB1R w KQkq - 0 1"
    legal_moves = [{"c3", "b5"}, {"d4", "b5"}]

    assert MR.get_san(fen, legal_moves, {"c3", "b5"}) == "Ncb5"
    assert MR.get_san(fen, legal_moves, {"d4", "b5"}) == "Ndb5"
  end

  test "rook moves that need rank to disambiguate" do
    fen = "1nbqkbn1/1pppppp1/r6r/p6p/P6P/R7/1PPPPPP1/RNBQKBN1 w Q - 0 1"
    legal_moves = [{"a1", "a2"}, {"a3", "a2"}]

    assert MR.get_san(fen, legal_moves, {"a1", "a2"}) == "R1a2"
    assert MR.get_san(fen, legal_moves, {"a3", "a2"}) == "R3a2"
  end

  test "rook moves that need file to disambiguate" do
    fen = "1nbqkbn1/1pppppp1/r6r/p6p/P6P/R7/1PPPPPP1/RNBQKBN1 b Q - 0 1"
    legal_moves = [{"a6", "d6"}, {"h6", "d6"}]

    assert MR.get_san(fen, legal_moves, {"a6", "d6"}) == "Rad6"
    assert MR.get_san(fen, legal_moves, {"h6", "d6"}) == "Rhd6"
  end

  test "queen moves that need rank and file to disambiguate" do
      fen = "rnbqkbnr/pppppppp/8/3Q1Q2/8/3Q1Q2/PPPPPPPP/RNB1KBNR w KQkq - 0 1"
      legal_moves = [{"d3", "e4"}, {"d5", "e4"}, {"f5", "e4"}, {"f3", "e4"}]

      assert MR.get_san(fen, legal_moves, {"d3", "e4"}) == "Qd3e4"
      assert MR.get_san(fen, legal_moves, {"d5", "e4"}) == "Qd5e4"
      assert MR.get_san(fen, legal_moves, {"f5", "e4"}) == "Qf5e4"
      assert MR.get_san(fen, legal_moves, {"f3", "e4"}) == "Qf3e4"
  end

  test "start position FEN to piece list" do
    start_fen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
    expected = ["r", "n", "b", "q", "k", "b", "n", "r", "p", "p", "p", "p", "p", "p", "p", "p", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", "P", "P", "P", "P", "P", "P", "P", "P", "R", "N", "B", "Q", "K", "B", "N", "R" ]
    assert MR.fen_to_piece_list(start_fen)  == expected
  end
  test "pawn move FEN to piece list" do
    fen = "rnbqkbnr/pppp1ppp/8/4p3/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
    expected = ["r", "n", "b", "q", "k", "b", "n", "r", "p", "p", "p", "p", " ", "p", "p", "p", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", "p", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", "P", "P", "P", "P", "P", "P", "P", "P", "R", "N", "B", "Q", "K", "B", "N", "R" ]
    assert MR.fen_to_piece_list(fen)  == expected
  end

  test "get piece at square for starting position" do
    fen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
    assert MR.get_piece_at_square("a1", fen) == {:ok, "R"}
    assert MR.get_piece_at_square("a2", fen) == {:ok, "P"}
    assert MR.get_piece_at_square("a7", fen) == {:ok, "p"}
    assert MR.get_piece_at_square("a8", fen) == {:ok, "r"}
    assert MR.get_piece_at_square("a4", fen) == {:ok, " "}
    assert MR.get_piece_at_square("h2", fen) == {:ok, "P"}
  end
  test "get piece at square for more interesting position" do
    # B60 sicillian defence
    fen = "r1bqkb1r/pp2pppp/2np1n2/6B1/3NP3/2N5/PPP2PPP/R2QKB1R b KQkq - 5 6"
    assert MR.get_piece_at_square("a1", fen) == {:ok, "R"}
    assert MR.get_piece_at_square("a2", fen) == {:ok, "P"}
    assert MR.get_piece_at_square("a7", fen) == {:ok, "p"}
    assert MR.get_piece_at_square("a8", fen) == {:ok, "r"}
    assert MR.get_piece_at_square("a4", fen) == {:ok, " "}
    assert MR.get_piece_at_square("h2", fen) == {:ok, "P"}
    assert MR.get_piece_at_square("e4", fen) == {:ok, "P"}
    assert MR.get_piece_at_square("d4", fen) == {:ok, "N"}
  end

  test "get_move_context" do
    fen = "rnbqkbnr/ppp2ppp/4p3/3p4/3N4/2N5/PPPPPPPP/R1BQKB1R w KQkq - 0 1"
    legal_moves = [{"c3", "b5"}, {"d4", "b5"}]
    assert MR.get_piece_at_square("c3", fen) == {:ok, "N"}
    assert MR.get_piece_at_square("d4", fen) == {:ok, "N"}
    assert MR.get_move_context("N", {"c3", "b5"}, legal_moves, fen) == [{:ok, %{rank: "4", file: :d}}]
    assert MR.get_move_context("N", {"c3", "b5"}, [{"c3", "b5"}], fen) == []
  end
  test "get moves that end at" do
    legal_moves = [{"c3", "b5"}, {"d4", "b5"}]
    assert MR.get_moves_that_end_at("b5", legal_moves) == legal_moves
    assert MR.get_moves_that_end_at("b5", []) == []
    assert MR.get_moves_that_end_at("a6", legal_moves) == []
    assert MR.get_moves_that_end_at("b6", [{"c3", "b5"}, {"d4", "b6"}]) == [{"d4", "b6"}]
  end
end
