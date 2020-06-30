module Board exposing (..)

import Element exposing (Element)
import Element.Background as Background
import Element.Border
import Element.Events
import Move exposing (Move)
import Piece exposing (Piece)
import Player exposing (Player)
import Set exposing (Set)
import Square exposing (Square)


type alias Board =
    List (List (Maybe Piece))


type alias RenderData msg =
    { selectablePieceSquares : Set Square
    , selectPieceEvent : Square -> msg
    , selectableMoveSquares : Set Square
    , selectMoveEvent : Square -> msg
    , lastPly : Maybe Move.MoveWithSan
    }


type alias RenderableSquare msg =
    { piece : Maybe Piece
    , properties : List (Element.Attribute msg)
    }


drawFromFen : Int -> String -> RenderData msg -> Player -> Element msg -> Element msg
drawFromFen screenWidth fen renderData bottomPlayer errorElement =
    let
        squareDrawFunc =
            \p s -> getSquareProperties renderData p s |> drawSquareWithAttributes
    in
    fen
        |> fenToBoard
        |> Maybe.map (\board -> draw screenWidth board bottomPlayer squareDrawFunc [])
        |> Maybe.withDefault errorElement


drawFromFenWithPromotions : Int -> String -> Player -> Maybe Move.MoveWithSan -> List Piece -> (Piece -> msg) -> msg -> Element msg -> Element msg
drawFromFenWithPromotions screenWidth fen bottomPlayer lastPly promotions promotionMsg cancelMsg errorElement =
    let
        cancelOverlay =
            Element.inFront
                (Element.el
                    [ Element.width Element.fill
                    , Element.height Element.fill
                    , Background.color (Element.rgba255 128 128 128 0.5)
                    , Element.Events.onClick cancelMsg
                    ]
                    Element.none
                )

        promotionOverlay =
            Element.inFront (drawPromotions screenWidth promotions promotionMsg)

        renderData =
            { selectablePieceSquares = Set.empty
            , selectPieceEvent = \_ -> cancelMsg
            , selectableMoveSquares = Set.empty
            , selectMoveEvent = \_ -> cancelMsg
            , lastPly = lastPly
            }

        squareDrawFunc =
            \p s -> getSquareProperties renderData p s |> drawSquareWithAttributes
    in
    fen
        |> fenToBoard
        |> Maybe.map (\board -> draw screenWidth board bottomPlayer squareDrawFunc [ cancelOverlay, promotionOverlay ])
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


draw : Int -> Board -> Player -> (Maybe Piece -> Square -> Element msg) -> List (Element.Attribute msg) -> Element msg
draw screenWidth board currentPlayer drawSquareFunc extraAttributes =
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
                [ Element.width Element.fill
                , Element.height Element.fill
                ]
                (List.map2 drawSquareFunc row rowCoords)
    in
    Element.column
        ([ Element.width (Element.px screenWidth)
         , Element.height (Element.px screenWidth)
         ]
            ++ extraAttributes
        )
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


drawPromotions : Int -> List Piece -> (Piece -> msg) -> Element msg
drawPromotions screenWidth pieces event =
    let
        promotions =
            pieces
                |> List.map
                    (\piece ->
                        Element.el
                            [ Element.width Element.fill
                            , Element.height Element.fill
                            , Element.Events.onClick (event piece)
                            ]
                            (drawPiece (Just piece))
                    )

        width =
            (screenWidth // 8) * List.length pieces
    in
    Element.row
        [ Element.width (Element.px width)
        , Element.centerX
        , Element.centerY
        , Background.color (Element.rgb255 90 90 90)
        ]
        promotions


drawSquareWithAttributes : RenderableSquare msg -> Element msg
drawSquareWithAttributes sq =
    Element.el
        ([ Element.padding 0
         , Element.width Element.fill
         , Element.height Element.fill
         ]
            ++ sq.properties
        )
        (drawPiece sq.piece)


getSquareProperties : RenderData msg -> Maybe Piece -> Square -> RenderableSquare msg
getSquareProperties renderData maybePiece square =
    let
        event =
            if Set.member square renderData.selectablePieceSquares then
                [ Element.Events.onClick (renderData.selectPieceEvent square) ]

            else if Set.member square renderData.selectableMoveSquares then
                [ Element.Events.onClick (renderData.selectMoveEvent square) ]

            else
                []

        overlay =
            if Set.member square renderData.selectableMoveSquares then
                [ Element.inFront possibleMoveOverlay ]

            else
                []

        isPartOfLastPly =
            case renderData.lastPly of
                Nothing ->
                    False

                Just move ->
                    move.start == square || move.end == square

        color =
            if Square.isLight square then
                if not isPartOfLastPly then
                    Element.rgb255 237 238 210

                else
                    Element.rgb255 255 0 210

            else if not isPartOfLastPly then
                Element.rgb255 0 150 53

            else
                Element.rgb255 255 0 53
    in
    { piece = maybePiece
    , properties = event ++ overlay ++ [ Background.color color ]
    }


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
