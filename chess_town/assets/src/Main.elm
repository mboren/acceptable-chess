port module Main exposing (..)

import Board
import Browser exposing (Document)
import Element
import Element.Input
import Json.Decode exposing (Decoder, field, string)
import Move exposing (Move)
import Piece exposing (Piece)
import Player exposing (Player)
import Set exposing (Set)
import Square exposing (Square)


port sendMessage : String -> Cmd msg


port sendMove : Move -> Cmd msg


port messageReceiver : (Json.Decode.Value -> msg) -> Sub msg


type Model
    = WaitingForInitialization
    | MyTurn { mySide : Player, legalMoves : List Move, board : String, history : List Move, selection : Selection }
    | WaitingForMoveToBeAccepted { mySide : Player, legalMoves : List Move, board : String, history : List Move, moveSent : Move }
    | OtherPlayersTurn { mySide : Player, board : String, history : List Move }
    | GameOver { mySide : Player, board : String, history : List Move, reason : GameOverReason }


type GameOverReason
    = Mate Player


type Selection
    = SelectingStart
    | SelectingEnd Square


type ServerGameStatus
    = Continue
    | Checkmate


type alias ServerGameState =
    { board : String
    , status : ServerGameStatus
    , playerToMove : Player
    , yourPlayer : Player -- TODO I don't like this naming
    , legalMoves : List Move
    , history : List Move
    }


init _ =
    ( WaitingForInitialization, sendMessage "ready" )


main : Program () Model Msg
main =
    Browser.document
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


type Msg
    = GetState Json.Decode.Value
    | NewSelectedMoveStart Square
    | NewSelectedMoveEnd Square


squareFromChars : Char -> Char -> Maybe Square
squareFromChars file rank =
    if
        List.member file [ 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h' ]
            && List.member rank [ '1', '2', '3', '4', '5', '6', '7', '8' ]
    then
        Just (String.fromList [ file, rank ])

    else
        Nothing


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NewSelectedMoveStart square ->
            case model of
                MyTurn data ->
                    ( MyTurn { data | selection = SelectingEnd square }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        NewSelectedMoveEnd end ->
            case model of
                MyTurn data ->
                    case data.selection of
                        SelectingEnd start ->
                            let
                                move =
                                    Move start end
                            in
                            ( WaitingForMoveToBeAccepted
                                { mySide = data.mySide
                                , legalMoves = data.legalMoves
                                , board = data.board
                                , history = data.history
                                , moveSent = move
                                }
                            , sendMove move
                            )

                        _ ->
                            ( model, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        GetState value ->
            case Json.Decode.decodeValue boardStateDecoder value of
                Err err ->
                    let
                        _ =
                            Json.Decode.errorToString err |> Debug.log "error"
                    in
                    ( model, Cmd.none )

                Ok state ->
                    case state.status of
                        Checkmate ->
                            ( GameOver
                                { mySide = state.yourPlayer
                                , board = state.board
                                , history = state.history
                                , reason = Mate (Player.other state.playerToMove)
                                }
                            , Cmd.none
                            )

                        Continue ->
                            let
                                newModel =
                                    case model of
                                        GameOver data ->
                                            model |> Debug.log "got continue after game over"

                                        WaitingForInitialization ->
                                            MyTurn
                                                { mySide = state.yourPlayer
                                                , legalMoves = state.legalMoves
                                                , board = state.board
                                                , history = state.history
                                                , selection = SelectingStart
                                                }

                                        WaitingForMoveToBeAccepted data ->
                                            if data.mySide == state.playerToMove then
                                                MyTurn
                                                    { mySide = data.mySide
                                                    , legalMoves = state.legalMoves
                                                    , board = state.board
                                                    , history = state.history
                                                    , selection = SelectingStart
                                                    }

                                            else
                                                OtherPlayersTurn
                                                    { mySide = data.mySide
                                                    , board = state.board
                                                    , history = state.history
                                                    }

                                        MyTurn data ->
                                            if data.mySide == state.playerToMove then
                                                MyTurn
                                                    { mySide = data.mySide
                                                    , legalMoves = state.legalMoves
                                                    , board = state.board
                                                    , history = state.history
                                                    , selection = data.selection
                                                    }

                                            else
                                                OtherPlayersTurn
                                                    { mySide = data.mySide
                                                    , board = state.board
                                                    , history = state.history
                                                    }

                                        OtherPlayersTurn data ->
                                            if data.mySide == state.playerToMove then
                                                MyTurn
                                                    { mySide = data.mySide
                                                    , legalMoves = state.legalMoves
                                                    , board = state.board
                                                    , history = state.history
                                                    , selection = SelectingStart
                                                    }

                                            else
                                                OtherPlayersTurn
                                                    { mySide = data.mySide
                                                    , board = state.board
                                                    , history = state.history
                                                    }
                            in
                            ( newModel, Cmd.none )


boardStateDecoder : Decoder ServerGameState
boardStateDecoder =
    Json.Decode.map6 ServerGameState
        (field "board" string)
        (field "status" gameStatusDecoder)
        (field "player_to_move" Player.decode)
        (field "player_color" Player.decode)
        (field "legal_moves" (Json.Decode.list moveDecoder))
        (field "history" (Json.Decode.list moveDecoder))


moveDecoder : Decoder { start : String, end : String }
moveDecoder =
    Json.Decode.map2 (\start end -> { start = start, end = end })
        (field "start" string)
        (field "end" string)


gameStatusDecoder : Decoder ServerGameStatus
gameStatusDecoder =
    string |> Json.Decode.andThen gameStatusDecoderHelp


gameStatusDecoderHelp s =
    case s of
        "continue" ->
            Json.Decode.succeed Continue

        "checkmate" ->
            Json.Decode.succeed Checkmate

        _ ->
            Json.Decode.fail ("Unhandled status: " ++ s)


subscriptions : Model -> Sub Msg
subscriptions model =
    messageReceiver GetState


getSelectablePieces : List Move -> Set Square
getSelectablePieces moves =
    List.map .start moves
        |> Set.fromList


getPossibleMoveEndsFromSquare : Square -> List Move -> Set Square
getPossibleMoveEndsFromSquare start moves =
    List.filter (\move -> move.start == start) moves
        |> List.map .end
        |> Set.fromList


getClickableSquares : Model -> ( ( Set Square, Square -> Msg ), ( Set Square, Square -> Msg ) )
getClickableSquares model =
    case model of
        MyTurn data ->
            case data.selection of
                SelectingStart ->
                    ( ( getSelectablePieces data.legalMoves, NewSelectedMoveStart )
                    , ( Set.empty, NewSelectedMoveEnd )
                    )

                SelectingEnd start ->
                    ( ( getSelectablePieces data.legalMoves, NewSelectedMoveStart )
                    , ( getPossibleMoveEndsFromSquare start data.legalMoves, NewSelectedMoveEnd )
                    )

        _ ->
            ( ( Set.empty, NewSelectedMoveStart )
            , ( Set.empty, NewSelectedMoveEnd )
            )


view : Model -> Document Msg
view model =
    let
        ( selectablePieces, selectableMoves ) =
            getClickableSquares model
    in
    { title = "chess"
    , body =
        [ Element.layout
            []
            (case model of
                GameOver data ->
                    let
                        reasonText =
                            case data.reason of
                                Mate winner ->
                                    Player.toString winner ++ " wins!"
                    in
                    Element.column
                        [ Element.width Element.fill ]
                        [ data.board
                            |> fenToBoard
                            |> Maybe.map (\board -> Board.draw board selectablePieces selectableMoves data.mySide data.mySide)
                            |> Maybe.withDefault Element.none
                        , Element.text reasonText
                        ]

                WaitingForInitialization ->
                    Element.text "waiting for state from backend"

                MyTurn data ->
                    Element.column
                        [ Element.width Element.fill ]
                        [ data.board
                            |> fenToBoard
                            |> Maybe.map (\board -> Board.draw board selectablePieces selectableMoves data.mySide data.mySide)
                            |> Maybe.withDefault Element.none
                        ]

                WaitingForMoveToBeAccepted data ->
                    Element.column
                        [ Element.width Element.fill ]
                        [ data.board
                            |> fenToBoard
                            |> Maybe.map (\board -> Board.draw board selectablePieces selectableMoves data.mySide data.mySide)
                            |> Maybe.withDefault Element.none
                        , Element.text "waiting"
                        ]

                OtherPlayersTurn data ->
                    Element.column
                        [ Element.width Element.fill ]
                        [ data.board
                            |> fenToBoard
                            |> Maybe.map (\board -> Board.draw board selectablePieces selectableMoves data.mySide (Player.other data.mySide))
                            |> Maybe.withDefault Element.none
                        , Element.text "waiting for other player to move"
                        ]
            )
        ]
    }


fenToBoard : String -> Maybe (List (List (Maybe Piece)))
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
