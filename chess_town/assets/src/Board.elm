module Board exposing (..)

import Element exposing (Element)
import Element.Background as Background
import Element.Border
import Element.Events
import Piece exposing (Piece)
import Player exposing (Player)
import Set exposing (Set)
import Square exposing (Square)


type alias Board =
    List (List (Maybe Piece))


drawFromFen : String -> ( Set Square, Square -> msg ) -> ( Set Square, Square -> msg ) -> Player -> Element msg -> Element msg
drawFromFen fen selectablePieces selectableMoves bottomPlayer errorElement =
    fen
        |> fenToBoard
        |> Maybe.map (\board -> draw board selectablePieces selectableMoves bottomPlayer)
        |> Maybe.withDefault errorElement


fenToBoard : String -> Maybe Board
fenToBoard fen =
    case getPositionPart fen of
        Nothing ->
            Nothing

        Just text ->
            text
                |> String.split "/"
                |> List.map rowToPieces
                |> Just


getPositionPart fen =
    String.split " " fen
        |> List.head


rowToPieces row =
    row
        |> replaceNumbers ""
        |> String.toList
        |> List.map Piece.fromChar


replaceNumbers : String -> String -> String
replaceNumbers processed unprocessed =
    case String.uncons unprocessed of
        Nothing ->
            processed

        Just ( head, tail ) ->
            if Char.isDigit head then
                replaceNumbers (processed ++ String.repeat (Maybe.withDefault 0 (String.toInt (String.fromChar head))) "_") tail

            else
                replaceNumbers (processed ++ String.fromChar head) tail


draw : Board -> ( Set Square, Square -> msg ) -> ( Set Square, Square -> msg ) -> Player -> Element msg
draw board ( selectablePieceSquares, selectPieceEvent ) ( selectableMoveSquares, selectMoveEvent ) currentPlayer =
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


possibleMoveOverlay =
    Element.el
        [ Element.Border.rounded 50
        , Background.color (Element.rgb255 255 0 0)
        , Element.width Element.fill
        , Element.height Element.fill
        , Element.scale 0.5
        , Element.alpha 0.5
        ]
        Element.none


drawSquare : Element.Length -> ( Set Square, Square -> msg ) -> ( Set Square, Square -> msg ) -> Maybe Piece -> Square -> Element msg
drawSquare size ( selectablePieceSquares, selectPieceEvent ) ( selectableMoveSquares, selectMoveEvent ) maybePiece square =
    let
        color =
            if Square.isLight square then
                Element.rgb255 237 238 210

            else
                Element.rgb255 0 150 53

        event =
            if Set.member square selectablePieceSquares then
                [ Element.Events.onClick (selectPieceEvent square) ]

            else if Set.member square selectableMoveSquares then
                [ Element.Events.onClick (selectMoveEvent square) ]

            else
                []

        overlay =
            if Set.member square selectableMoveSquares then
                possibleMoveOverlay

            else
                Element.none
    in
    Element.el
        ([ Background.color color
         , Element.padding 0
         , Element.width size
         , Element.height size
         , Element.inFront overlay
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
