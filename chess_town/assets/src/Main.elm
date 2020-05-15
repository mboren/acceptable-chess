port module Main exposing (..)

import Browser
import Html exposing (Html, text)
import Html.Attributes
import Html.Events
import Json.Decode exposing (Decoder, field, string, succeed)
import Piece exposing (Piece)
import Player exposing (Player)


port sendMessage : String -> Cmd msg


port messageReceiver : (Json.Decode.Value -> msg) -> Sub msg


type GameStatus
    = PlayerToMove Player (List Move)
    | Winner Player


type alias Move =
    String


type alias GameState =
    { board : String
    , status : GameStatus
    , history : List Move
    }


type ServerGameStatus
    = Continue
    | Checkmate


type alias ServerGameState =
    { board : String
    , status : ServerGameStatus
    , playerToMove : Player
    , legalMoves : List { start : String, end : String }
    }


type Model
    = WaitingForInitialization
    | Loaded GameState String


transformServerGameState : ServerGameState -> GameState
transformServerGameState { board, status, playerToMove, legalMoves } =
    let
        newStatus =
            case status of
                Continue ->
                    PlayerToMove playerToMove (List.map (\{ start, end } -> start ++ end) legalMoves)

                Checkmate ->
                    Winner (Player.other playerToMove)
    in
    { board = board
    , status = newStatus
    , history = []
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


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NewMoveText text ->
            case model of
                WaitingForInitialization ->
                    ( WaitingForInitialization, Cmd.none )

                Loaded state oldText ->
                    ( Loaded state text, Cmd.none )

        SendMove ->
            case model of
                WaitingForInitialization ->
                    ( model, Cmd.none )

                Loaded state text ->
                    let
                        _ =
                            Debug.log "sending move from elm" text
                    in
                    ( Loaded state "", sendMessage text )

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
                        transformedState =
                            transformServerGameState state

                        newModel =
                            case model of
                                WaitingForInitialization ->
                                    Loaded transformedState ""

                                Loaded oldState text ->
                                    Loaded transformedState text
                    in
                    ( newModel, Cmd.none )


boardStateDecoder : Decoder ServerGameState
boardStateDecoder =
    Json.Decode.map4 ServerGameState
        (field "board" string)
        (field "status" gameStatusDecoder)
        (field "player_to_move" Player.decode)
        (field "legal_moves" (succeed []))


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

        Loaded state movetext ->
            Html.div []
                [ text state.board
                , boardToHtml (state.board |> fenToBoard |> Maybe.withDefault [ [] ])
                , Html.input [ Html.Attributes.value movetext, Html.Events.onInput NewMoveText ] []
                , Html.button [ Html.Events.onClick SendMove ] [ text "submit" ]
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
