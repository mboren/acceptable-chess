port module Main exposing (..)

import Board
import Browser exposing (Document)
import Element exposing (Element)
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
    | Resignation Player


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
    , winner : Maybe Player
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
    | Resign


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

        Resign ->
            ( model, sendMessage "resign" )

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
                            case state.winner of
                                Just player ->
                                    ( GameOver
                                        { mySide = state.yourPlayer
                                        , board = state.board
                                        , history = state.history
                                        , reason = Resignation player
                                        }
                                    , Cmd.none
                                    )
                                Nothing ->
                                    let
                                        selection =
                                            case model of
                                                MyTurn data ->
                                                    data.selection

                                                _ ->
                                                    SelectingStart

                                        newModel =
                                            case model of
                                                GameOver _ ->
                                                    model |> Debug.log "got continue after game over"

                                                _ ->
                                                    if state.yourPlayer == state.playerToMove then
                                                        MyTurn
                                                            { mySide = state.yourPlayer
                                                            , legalMoves = state.legalMoves
                                                            , board = state.board
                                                            , history = state.history
                                                            , selection = selection
                                                            }

                                                    else
                                                        OtherPlayersTurn
                                                            { mySide = state.yourPlayer
                                                            , board = state.board
                                                            , history = state.history
                                                            }
                                    in
                                    ( newModel, Cmd.none )


boardStateDecoder : Decoder ServerGameState
boardStateDecoder =
    Json.Decode.map7 ServerGameState
        (field "board" string)
        (field "status" gameStatusDecoder)
        (field "player_to_move" Player.decode)
        (field "player_color" Player.decode)
        (field "legal_moves" (Json.Decode.list moveDecoder))
        (field "history" (Json.Decode.list moveDecoder))
        (field "winner" ((Json.Decode.nullable Player.decode)))

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

                                Resignation winner ->
                                    Player.toString winner ++ " wins by resignation"
                    in
                    Element.column
                        [ Element.width Element.fill ]
                        [ Board.drawFromFen data.board selectablePieces selectableMoves data.mySide (Element.text ("Error parsing FEN: " ++ data.board))
                        , Element.text reasonText
                        ]

                WaitingForInitialization ->
                    Element.text "waiting for state from backend"

                MyTurn data ->
                    Element.column
                        [ Element.width Element.fill ]
                        [ Board.drawFromFen data.board selectablePieces selectableMoves data.mySide (Element.text ("Error parsing FEN: " ++ data.board))
                        , resignButton
                        ]

                WaitingForMoveToBeAccepted data ->
                    Element.column
                        [ Element.width Element.fill ]
                        [ Board.drawFromFen data.board selectablePieces selectableMoves data.mySide (Element.text ("Error parsing FEN: " ++ data.board))
                        , Element.text "waiting"
                        , resignButton
                        ]

                OtherPlayersTurn data ->
                    Element.column
                        [ Element.width Element.fill ]
                        [ Board.drawFromFen data.board selectablePieces selectableMoves data.mySide (Element.text ("Error parsing FEN: " ++ data.board))
                        , Element.text "waiting for other player to move"
                        , resignButton
                        ]
            )
        ]
    }


resignButton : Element Msg
resignButton =
    Element.Input.button [] { onPress = Just Resign, label = Element.text "Offer resignation" }
