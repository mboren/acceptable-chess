module Move exposing (..)

import Piece exposing (Piece)
import Square exposing (Square)


type alias Move =
    { start : Square, end : Square, promotion : Maybe Piece.PieceKind }

type alias MoveWithSan =
    { start : Square, end : Square, promotion : Maybe Piece.PieceKind, san : String }

type alias MoveWithStringPromotion =
    { start : Square, end : Square, promotion : Maybe String }

getPossiblePromotions : List Move -> Square -> Square -> List Piece.PieceKind
getPossiblePromotions moves start end =
    List.filter (\move->move.start == start && move.end == end) moves
    |> List.filterMap .promotion
