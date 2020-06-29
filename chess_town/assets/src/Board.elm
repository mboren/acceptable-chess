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


drawFromFen : Int -> String -> ( Set Square, Square -> msg ) -> ( Set Square, Square -> msg ) -> Player -> Element msg -> Element msg
drawFromFen screenWidth fen selectablePieces selectableMoves bottomPlayer errorElement =
    let
        squareDrawFunc =
            drawSquare selectablePieces selectableMoves
    in
    fen
        |> fenToBoard
        |> Maybe.map (\board -> draw screenWidth board bottomPlayer squareDrawFunc [])
        |> Maybe.withDefault errorElement


drawFromFenWithPromotions : Int -> String -> Player -> List Piece -> (Piece -> msg) -> msg -> Element msg -> Element msg
drawFromFenWithPromotions screenWidth fen bottomPlayer promotions promotionMsg cancelMsg errorElement =
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
            Element.inFront (drawPromotions promotions promotionMsg)
    in
    fen
        |> fenToBoard
        |> Maybe.map (\board -> draw screenWidth board bottomPlayer (drawSquareWithAttributes []) [ cancelOverlay, promotionOverlay ])
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


drawPromotions : List Piece -> (Piece -> msg) -> Element msg
drawPromotions pieces event =
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
    in
    Element.row
        [ Element.width (Element.px 400)
        , Element.centerX
        , Element.centerY
        , Background.color (Element.rgb255 90 90 90)
        ]
        promotions


drawSquareWithAttributes attributes maybePiece square =
    let
        color =
            if Square.isLight square then
                Element.rgb255 237 238 210

            else
                Element.rgb255 0 150 53
    in
    Element.el
        ([ Background.color color
         , Element.padding 0
         , Element.width Element.fill
         , Element.height Element.fill
         ]
            ++ attributes
        )
        (drawPiece maybePiece)


drawSquare : ( Set Square, Square -> msg ) -> ( Set Square, Square -> msg ) -> Maybe Piece -> Square -> Element msg
drawSquare ( selectablePieceSquares, selectPieceEvent ) ( selectableMoveSquares, selectMoveEvent ) maybePiece square =
    let
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
    drawSquareWithAttributes (Element.inFront overlay :: event) maybePiece square


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
