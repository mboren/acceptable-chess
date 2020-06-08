defmodule MoveAnalysisTest do
  use ExUnit.Case
  alias MoveAnalysis, as: MA

  defp mm(s, e) do
    %{start: s, end: e}
  end
  defp mm(s, e, p) do
    %{start: s, end: e, promotion: p}
  end

  test "pawn capture" do
    fen = "rnbqkbnr/ppp1pppp/3p4/4P3/8/8/PPPP1PPP/RNBQKBNR w KQkq - 0 1"
    legal_move = mm("d6", "e5")
    assert MA.get_captured_piece(legal_move, fen) == "P"
  end

  test "no capture" do
    fen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
    legal_move = mm("e2", "e4")
    assert MA.get_captured_piece(legal_move, fen) == nil
  end
end
