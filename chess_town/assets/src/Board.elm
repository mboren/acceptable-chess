module Board exposing (..)

import Element exposing (Element)
import Element.Background as Background
import Element.Events
import Piece exposing (Piece)
import Player exposing (Player)
import Set exposing (Set)
import Square exposing (Square)


whiteSquares =
    Set.fromList [ "e6", "c8", "h7", "c4", "b1", "h3", "d7", "f3", "b7", "f1", "a4", "b3", "c6", "e4", "b5", "h1", "d1", "d3", "f7", "e8", "g6", "g4", "g8", "a6", "c2", "d5", "g2", "a2", "e2", "a8", "f5", "h5" ]


blackSquares =
    Set.fromList [ "e7", "c7", "d8", "a5", "a7", "e1", "f4", "d2", "g1", "h8", "e3", "g5", "g7", "a3", "b8", "h4", "f8", "e5", "h2", "f2", "a1", "b4", "d4", "c3", "h6", "g3", "c1", "f6", "c5", "b2", "d6", "b6" ]


draw : List (List (Maybe Piece)) -> ( Set Square, Square -> msg ) -> ( Set Square, Square -> msg ) -> Player -> Player -> Element msg
draw board ( selectablePieceSquares, selectPieceEvent ) ( selectableMoveSquares, selectMoveEvent ) currentPlayer playerToMove =
    let
        files =
            [ "a", "b", "c", "d", "e", "f", "g", "h" ]

        ranks =
            [ "8", "7", "6", "5", "4", "3", "2", "1" ]

        concatEach row =
            List.map (\f -> f ++ row) files

        coordinates =
            List.map concatEach ranks

        drawRow : List (Maybe Piece) -> List Square -> Element msg
        drawRow row rowCoords =
            Element.row
                []
                (List.map2 (drawSquare (Element.px 45) ( selectablePieceSquares, selectPieceEvent ) ( selectableMoveSquares, selectMoveEvent )) row rowCoords)
    in
    Element.column
        [ Element.width Element.fill ]
        (List.map2 drawRow (orientBoard currentPlayer board) (orientBoard currentPlayer coordinates))


drawSquare : Element.Length -> ( Set Square, Square -> msg ) -> ( Set Square, Square -> msg ) -> Maybe Piece -> Square -> Element msg
drawSquare size ( selectablePieceSquares, selectPieceEvent ) ( selectableMoveSquares, selectMoveEvent ) maybePiece square =
    let
        ( unselectedColor, selectedColor ) =
            if Set.member square whiteSquares then
                ( Element.rgb255 237 238 210, Element.rgb255 255 241 0 )

            else
                ( Element.rgb255 0 150 53, Element.rgb255 255 241 0 )

        color =
            if Set.member square selectablePieceSquares then
                selectedColor

            else if Set.member square selectableMoveSquares then
                selectedColor

            else
                unselectedColor

        event =
            if Set.member square selectablePieceSquares then
                [ Element.Events.onClick (selectPieceEvent square) ]

            else if Set.member square selectableMoveSquares then
                [ Element.Events.onClick (selectMoveEvent square) ]

            else
                []
    in
    Element.el
        ([ Background.color color
         , Element.padding 0
         , Element.width size
         , Element.height size
         ]
            ++ event
        )
        (drawPiece maybePiece)


orientBoard : Player -> List (List a) -> List (List a)
orientBoard player board =
    case player of
        Player.White ->
            board

        Player.Black ->
            List.reverse board
                |> List.map List.reverse


drawPiece : Maybe Piece -> Element msg
drawPiece maybePiece =
    case maybePiece of
        Nothing ->
            Element.none

        Just p ->
            Element.image [] { src = pieceToFileName p, description = Piece.toString p }


pieceToFileName piece =
    let
        color =
            case piece.player of
                Player.White ->
                    "l"

                Player.Black ->
                    "d"

        pieceKind =
            String.toLower (Piece.pieceKindToString piece.kind)
    in
    "../../images/Chess_" ++ pieceKind ++ color ++ "t45.svg"
