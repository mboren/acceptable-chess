module Piece exposing (..)

import Player exposing (Player(..))


type PieceKind
    = Pawn
    | Rook
    | Knight
    | Bishop
    | King
    | Queen


type alias Piece =
    { kind : PieceKind
    , player : Player
    }


fromChar : Char -> Maybe Piece
fromChar c =
    case c of
        'p' ->
            Just (Piece Pawn Black)

        'r' ->
            Just (Piece Rook Black)

        'n' ->
            Just (Piece Knight Black)

        'b' ->
            Just (Piece Bishop Black)

        'k' ->
            Just (Piece King Black)

        'q' ->
            Just (Piece Queen Black)

        'P' ->
            Just (Piece Pawn White)

        'R' ->
            Just (Piece Rook White)

        'N' ->
            Just (Piece Knight White)

        'B' ->
            Just (Piece Bishop White)

        'K' ->
            Just (Piece King White)

        'Q' ->
            Just (Piece Queen White)

        _ ->
            Nothing


toString : Piece -> String
toString { kind, player } =
    case ( kind, player ) of
        ( Pawn, Black ) ->
            "p"

        ( Rook, Black ) ->
            "r"

        ( Knight, Black ) ->
            "n"

        ( Bishop, Black ) ->
            "b"

        ( King, Black ) ->
            "k"

        ( Queen, Black ) ->
            "q"

        ( Pawn, White ) ->
            "P"

        ( Rook, White ) ->
            "R"

        ( Knight, White ) ->
            "N"

        ( Bishop, White ) ->
            "B"

        ( King, White ) ->
            "K"

        ( Queen, White ) ->
            "Q"

pieceKindToString pk =
    case pk of
        Pawn ->
            "p"

        Rook ->
            "r"

        Knight ->
            "n"

        Bishop ->
            "b"

        King ->
            "k"

        Queen ->
            "q"