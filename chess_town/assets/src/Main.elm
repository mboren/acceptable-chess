port module Main exposing (..)

import Browser
import Html exposing (Html, text)
import Html.Attributes
import Html.Events
import Json.Decode exposing (Decoder, field, string, succeed)
import Piece exposing (Piece)
import Player exposing (Player)


port sendMessage : String -> Cmd msg
port sendMove : Move -> Cmd msg


port messageReceiver : (Json.Decode.Value -> msg) -> Sub msg


type Model
    = WaitingForInitialization
    | MyTurn { mySide : Player, legalMoves : List Move, board : String, history : List Move, selection : Selection, moveText : String }
    | WaitingForMoveToBeAccepted { mySide : Player, legalMoves : List Move, board : String, history : List Move, moveSent : Move }
    | OtherPlayersTurn { mySide : Player, board : String, history : List Move }


type Selection
    = SelectingStart
    | SelectingEnd Square
    | SelectedMove Move


type alias Move =
    { start : Square, end : Square }


type alias Square =
    String


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
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


type Msg
    = GetState Json.Decode.Value
    | NewMoveText String
    | SendMove


squareFromChars : Char -> Char -> Maybe Square
squareFromChars file rank =
    if
        List.member file [ 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h' ]
            && List.member rank [ '1', '2', '3', '4', '5', '6', '7', '8' ]
    then
        Just (String.fromList [ file, rank ])

    else
        Nothing


squaresFromText : String -> Selection
squaresFromText text =
    case String.toList text of
        [ file, rank ] ->
            case squareFromChars file rank of
                Nothing ->
                    SelectingStart

                Just sq ->
                    SelectingEnd sq

        [ startFile, startRank, endFile, endRank ] ->
            case ( squareFromChars startFile startRank, squareFromChars endFile endRank ) of
                ( Just start, Nothing ) ->
                    SelectingEnd start

                ( Just start, Just end ) ->
                    SelectedMove (Move start end)

                _ ->
                    SelectingStart

        _ ->
            SelectingStart


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NewMoveText text ->
            case model of
                MyTurn data ->
                    let
                        newSelection =
                            squaresFromText text
                    in
                    ( MyTurn { data | selection = newSelection, moveText = text }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        SendMove ->
            case model of
                MyTurn data ->
                    let
                        _ =
                            Debug.log "sending move from elm" data.moveText
                    in
                    case data.selection of
                        SelectedMove move ->
                            ( WaitingForMoveToBeAccepted { mySide = data.mySide, legalMoves = data.legalMoves, board = data.board, history = data.history, moveSent = move }
                            , sendMove move
                            )

                        _ ->
                            ( model, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        GetState value ->
            let
                _ =
                    Debug.log "Got text: " value
            in
            case Json.Decode.decodeValue boardStateDecoder value of
                Err err ->
                    let
                        _ =
                            Json.Decode.errorToString err |> Debug.log "error"
                    in
                    ( model, Cmd.none )

                Ok state ->
                    let
                        newModel =
                            case model of
                                WaitingForInitialization ->
                                    MyTurn
                                        { mySide = state.yourPlayer
                                        , legalMoves = state.legalMoves
                                        , board = state.board
                                        , history = state.history
                                        , selection = SelectingStart
                                        , moveText = ""
                                        }

                                WaitingForMoveToBeAccepted data ->
                                    if data.mySide == state.playerToMove then
                                        MyTurn
                                            { mySide = data.mySide
                                            , legalMoves = state.legalMoves
                                            , board = state.board
                                            , history = state.history
                                            , selection = SelectingStart
                                            , moveText = ""
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
                                            , moveText = data.moveText
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
                                            , moveText = ""
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


view : Model -> Html Msg
view model =
    case model of
        WaitingForInitialization ->
            text "waiting for state from backend"

        MyTurn data ->
            Html.div []
                [ boardToHtml (data.board |> fenToBoard |> Maybe.withDefault [ [] ])
                , Html.input [ Html.Attributes.value data.moveText, Html.Events.onInput NewMoveText ] []
                , Html.button [ Html.Events.onClick SendMove ] [ text "submit" ]
                ]

        WaitingForMoveToBeAccepted data ->
            Html.div []
                [ boardToHtml (data.board |> fenToBoard |> Maybe.withDefault [ [] ])
                , text "waiting"
                ]

        OtherPlayersTurn data ->
            Html.div []
                [ boardToHtml (data.board |> fenToBoard |> Maybe.withDefault [ [] ])
                , text "waiting for other player to move"
                ]


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


boardToHtml : List (List (Maybe Piece)) -> Html Msg
boardToHtml board =
    Html.pre [] [ Html.text (boardToText board) ]


boardToText board =
    board
        |> List.map (List.map (Maybe.map Piece.toString))
        |> List.map (List.map (Maybe.withDefault "-"))
        |> List.map (String.join "")
        |> String.join "\n"
