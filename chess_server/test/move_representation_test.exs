defmodule MoveRepresentationTest do
  use ExUnit.Case

  alias MoveRepresentation, as: MR

  @moduletag :capture_log

  doctest MoveRepresentation

  test "module exists" do
    assert is_list(MoveRepresentation.module_info())
  end



  test "get_san" do
    start_fen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
    legal_moves = [ {"h2", "h4"}, {"h2", "h3"}, {"g2", "g4"}, {"g2", "g3"}, {"f2", "f4"}, {"f2", "f3"}, {"e2", "e4"}, {"e2", "e3"}, {"d2", "d4"}, {"d2", "d3"}, {"c2", "c4"}, {"c2", "c3"}, {"b2", "b4"}, {"b2", "b3"}, {"a2", "a4"}, {"a2", "a3"}, {"g1", "h3"}, {"g1", "f3"}, {"b1", "c3"}, {"b1", "a3"} ]
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

  test "get piece at index" do
    fen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
    assert MR.get_piece_at_square("a1", fen) == {:ok, "R"}
    assert MR.get_piece_at_square("a2", fen) == {:ok, "P"}
    assert MR.get_piece_at_square("a7", fen) == {:ok, "p"}
    assert MR.get_piece_at_square("a8", fen) == {:ok, "r"}
    assert MR.get_piece_at_square("a4", fen) == {:ok, " "}
    assert MR.get_piece_at_square("h2", fen) == {:ok, "P"}
  end
end
