defmodule MoveRepresentationTest do
  use ExUnit.Case

  alias MoveRepresentation, as: MR

  @moduletag :capture_log

  defp mm(s, e) do
    %{start: s, end: e}
  end
  defp mm(s, e, p) do
    %{start: s, end: e, promotion: p}
  end

  test "en passant" do
    fen = "rnbqkbnr/ppppp1pp/8/4Pp2/8/8/PPPP1PPP/RNBQKBNR w KQkq f6 0 1"
    legal_move = mm("e5", "f6")
    assert MR.get_san(fen, [legal_move], legal_move) == "exf6"
  end

  test "pawn capture" do
    fen = "rnbqkbnr/ppp1pppp/3p4/4P3/8/8/PPPP1PPP/RNBQKBNR w KQkq - 0 1"
    legal_move = mm("d6", "e5")
    assert MR.get_san(fen, [legal_move], legal_move) == "dxe5"
  end

  test "white pawn promotion" do
    fen = "rnbqkbn1/pppppppP/8/8/8/8/PPPPPPP1/RNBQKBNR w KQq - 0 1"
    legal_moves = [mm("h7", "h8", :n) , mm("h7", "h8", :q), mm("h7", "h8", :r), mm("h7", "h8", :b), mm("h7", "g8", :n), mm("h7", "g8", :q), mm("h7", "g8", :r), mm("h7", "g8", :b)]
    assert MR.get_san(fen, legal_moves, mm("h7", "h8", :n)) == "h8=N"
    assert MR.get_san(fen, legal_moves, mm("h7", "g8", :q)) == "hxg8=Q"
  end
  test "implicit white pawn promotion" do
    fen = "rnbqkbn1/pppppppP/8/8/8/8/PPPPPPP1/RNBQKBNR w KQq - 0 1"
    legal_moves = [mm("h7", "h8", :n) , mm("h7", "h8", :q), mm("h7", "h8", :r), mm("h7", "h8", :b), mm("h7", "g8", :n), mm("h7", "g8", :q), mm("h7", "g8", :r), mm("h7", "g8", :b)]
    assert MR.get_san(fen, legal_moves, mm("h7", "h8")) == "h8=Q"
    assert MR.get_san(fen, legal_moves, mm("h7", "g8")) == "hxg8=Q"
  end

  test "black pawn promotion" do
    fen = "rnbqkbnr/ppppppp1/8/8/8/8/PPPPPPPp/RNBQKB2 b Qkq - 0 1"
    legal_moves = [mm("h2", "h1", :n) , mm("h2", "h1", :q) , mm("h2", "h1", :r) , mm("h2", "h1", :b)]
    assert MR.get_san(fen, legal_moves, mm("h2", "h1", :n)) == "h1=N"
    assert MR.get_san(fen, legal_moves, mm("h2", "h1", :r)) == "h1=R"
    assert MR.get_san(fen, legal_moves, mm("h2", "h1", :b)) == "h1=B"
    assert MR.get_san(fen, legal_moves, mm("h2", "h1", :q)) == "h1=Q"
  end

  test "implicit black pawn promotion" do
    fen = "rnbqkbnr/ppppppp1/8/8/8/8/PPPPPPPp/RNBQKB2 b Qkq - 0 1"
    legal_moves = [mm("h2", "h1", :n) , mm("h2", "h1", :q) , mm("h2", "h1", :r) , mm("h2", "h1", :b)]
    assert MR.get_san(fen, legal_moves, mm("h2", "h1")) == "h1=Q"
  end

  test "get_san" do
    start_fen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
    legal_moves = [mm("h2", "h4"), mm("h2", "h3"), mm("g2", "g4"), mm("g2", "g3"), mm("f2", "f4"), mm("f2", "f3"), mm("e2", "e4"), mm("e2", "e3"), mm("d2", "d4"), mm("d2", "d3"), mm("c2", "c4"), mm("c2", "c3"), mm("b2", "b4"), mm("b2", "b3"), mm("a2", "a4"), mm("a2", "a3"), mm("g1", "h3"), mm("g1", "f3"), mm("b1", "c3"), mm("b1", "a3")]
    result = MR.get_san(start_fen, legal_moves, Enum.at(legal_moves, 0))
    assert result == "h4"
    assert MR.get_san(start_fen, legal_moves, mm("b1", "c3")) == "Nc3"
  end

  test "castling san" do
    fen = "r1bqk1nr/pp1n1pbp/2p1p1p1/3p4/3P1B2/2NQ1NP1/PPP1PPBP/R3K2R w KQkq - 0 1"
    white_kingside_castle = mm("e1", "g1")
    white_queenside_castle = mm("e1", "c1")
    legal_moves = [white_kingside_castle, white_queenside_castle]

    assert MR.get_san(fen, legal_moves, white_kingside_castle ) == "O-O"
    assert MR.get_san(fen, legal_moves, white_queenside_castle ) == "O-O-O"
  end

  test "capture san" do
    fen = "rnbqkbnr/ppp1pppp/8/3p4/8/2N5/PPPPPPPP/R1BQKBNR w KQkq - 0 1"
    knight_capture = mm("c3", "d5")
    legal_moves = [knight_capture]

    assert MR.get_san(fen, legal_moves, knight_capture) == "Nxd5"
  end

  test "ambiguous san knight move" do
    fen = "rnbqkbnr/ppp2ppp/4p3/3p4/3N4/2N5/PPPPPPPP/R1BQKB1R w KQkq - 0 1"
    legal_moves = [mm("c3", "b5"), mm("d4", "b5")]

    assert MR.get_san(fen, legal_moves, mm("c3", "b5")) == "Ncb5"
    assert MR.get_san(fen, legal_moves, mm("d4", "b5")) == "Ndb5"
  end

  test "rook moves that need rank to disambiguate" do
    fen = "1nbqkbn1/1pppppp1/r6r/p6p/P6P/R7/1PPPPPP1/RNBQKBN1 w Q - 0 1"
    legal_moves = [mm("a1", "a2"), mm("a3", "a2")]

    assert MR.get_san(fen, legal_moves, mm("a1", "a2")) == "R1a2"
    assert MR.get_san(fen, legal_moves, mm("a3", "a2")) == "R3a2"
  end

  test "rook moves that need file to disambiguate" do
    fen = "1nbqkbn1/1pppppp1/r6r/p6p/P6P/R7/1PPPPPP1/RNBQKBN1 b Q - 0 1"
    legal_moves = [mm("a6", "d6"), mm("h6", "d6")]

    assert MR.get_san(fen, legal_moves, mm("a6", "d6")) == "Rad6"
    assert MR.get_san(fen, legal_moves, mm("h6", "d6")) == "Rhd6"
  end

  test "queen moves that need rank and file to disambiguate" do
      fen = "rnbqkbnr/pppppppp/8/3Q1Q2/8/3Q1Q2/PPPPPPPP/RNB1KBNR w KQkq - 0 1"
      legal_moves = [mm("d3", "e4"), mm("d5", "e4"), mm("f5", "e4"), mm("f3", "e4")]

      assert MR.get_san(fen, legal_moves, mm("d3", "e4")) == "Qd3e4"
      assert MR.get_san(fen, legal_moves, mm("d5", "e4")) == "Qd5e4"
      assert MR.get_san(fen, legal_moves, mm("f5", "e4")) == "Qf5e4"
      assert MR.get_san(fen, legal_moves, mm("f3", "e4")) == "Qf3e4"
  end


  test "get_move_context" do
    fen = "rnbqkbnr/ppp2ppp/4p3/3p4/3N4/2N5/PPPPPPPP/R1BQKB1R w KQkq - 0 1"
    piece_list = Position.fen_to_piece_list(fen)
    legal_moves = [mm("c3", "b5"), mm("d4", "b5")]
    assert MR.get_move_context("N", mm("c3", "b5"), legal_moves, piece_list) == [{:ok, %{rank: "4", file: :d}}]
    assert MR.get_move_context("N", mm("c3", "b5"), [mm("c3", "b5")], piece_list) == []
  end
  test "get moves that end at" do
    legal_moves = [mm("c3", "b5"), mm("d4", "b5")]
    assert MR.get_moves_that_end_at("b5", legal_moves) == legal_moves
    assert MR.get_moves_that_end_at("b5", []) == []
    assert MR.get_moves_that_end_at("a6", legal_moves) == []
    assert MR.get_moves_that_end_at("b6", [mm("c3", "b5"), mm("d4", "b6")]) == [mm("d4", "b6")]
  end
end
