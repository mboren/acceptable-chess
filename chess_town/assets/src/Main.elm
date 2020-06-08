port module Main exposing (..)

import Board
import Browser exposing (Document)
import Element exposing (Element)
import Element.Background
import Element.Border as Border
import Element.Input
import Json.Decode exposing (Decoder, field, string)
import Move exposing (Move, MoveWithSan)
import Piece exposing (Piece)
import Player exposing (Player)
import Set exposing (Set)
import Square exposing (Square)


port sendMessage : String -> Cmd msg


port sendMove : Move -> Cmd msg


port messageReceiver : (Json.Decode.Value -> msg) -> Sub msg


type alias History =
    List MoveWithSan


type Model
    = WaitingForInitialization
    | MyTurn
        { mySide : Player
        , myLostPieces : List Piece
        , otherPlayerLostPieces : List Piece
        , legalMoves : List Move
        , board : String
        , history : History
        , selection : Selection
        }
    | WaitingForMoveToBeAccepted
        { mySide : Player
        , myLostPieces : List Piece
        , otherPlayerLostPieces : List Piece
        , legalMoves : List Move
        , board : String
        , history : History
        , moveSent : Move
        }
    | OtherPlayersTurn
        { mySide : Player
        , myLostPieces : List Piece
        , otherPlayerLostPieces : List Piece
        , board : String
        , history : History
        }
    | GameOver
        { mySide : Player
        , myLostPieces : List Piece
        , otherPlayerLostPieces : List Piece
        , board : String
        , history : History
        , reason : GameOverReason
        }


type alias CommonModelData a =
    { a
        | history : History
        , otherPlayerLostPieces : List Piece
        , myLostPieces : List Piece
        , board : String
        , mySide : Player
    }


type GameOverReason
    = Mate Player
    | Resignation Player


type Selection
    = SelectingStart
    | SelectingEnd Square


type ServerGameStatus
    = Continue
    | Over GameOverReason


type alias ServerGameState =
    { board : String
    , status : ServerGameStatus
    , playerToMove : Player
    , yourPlayer : Player -- TODO I don't like this naming
    , legalMoves : List Move
    , history : History
    , blackCapturedPieces : List Piece
    , whiteCapturedPieces : List Piece
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
                                , myLostPieces = data.myLostPieces
                                , otherPlayerLostPieces = data.otherPlayerLostPieces
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
                        Over reason ->
                            case reason of
                                Mate winner ->
                                    ( GameOver
                                        { mySide = state.yourPlayer
                                        , myLostPieces = getLostPieces state.yourPlayer state
                                        , otherPlayerLostPieces = getLostPieces (Player.other state.yourPlayer) state
                                        , board = state.board
                                        , history = state.history
                                        , reason = Mate winner
                                        }
                                    , Cmd.none
                                    )

                                Resignation winner ->
                                    ( GameOver
                                        { mySide = state.yourPlayer
                                        , myLostPieces = getLostPieces state.yourPlayer state
                                        , otherPlayerLostPieces = getLostPieces (Player.other state.yourPlayer) state
                                        , board = state.board
                                        , history = state.history
                                        , reason = Resignation winner
                                        }
                                    , Cmd.none
                                    )

                        Continue ->
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
                                                    , myLostPieces = getLostPieces state.yourPlayer state
                                                    , otherPlayerLostPieces = getLostPieces (Player.other state.yourPlayer) state
                                                    , legalMoves = state.legalMoves
                                                    , board = state.board
                                                    , history = state.history
                                                    , selection = selection
                                                    }

                                            else
                                                OtherPlayersTurn
                                                    { mySide = state.yourPlayer
                                                    , myLostPieces = getLostPieces state.yourPlayer state
                                                    , otherPlayerLostPieces = getLostPieces (Player.other state.yourPlayer) state
                                                    , board = state.board
                                                    , history = state.history
                                                    }
                            in
                            ( newModel, Cmd.none )


getLostPieces : Player -> ServerGameState -> List Piece
getLostPieces myPlayer data =
    case myPlayer of
        Player.White ->
            data.whiteCapturedPieces

        Player.Black ->
            data.blackCapturedPieces


decodeApply : Decoder a -> Decoder (a -> b) -> Decoder b
decodeApply =
    Json.Decode.map2 (|>)


required : String -> Decoder a -> Decoder (a -> b) -> Decoder b
required fieldName itemDecoder functionDecoder =
    decodeApply (field fieldName itemDecoder) functionDecoder


boardStateDecoder : Decoder ServerGameState
boardStateDecoder =
    Json.Decode.succeed RawServerGameState
        |> required "board" string
        |> required "status" string
        |> required "player_to_move" Player.decode
        |> required "player_color" Player.decode
        |> required "legal_moves" (Json.Decode.list moveDecoder)
        |> required "history" (Json.Decode.list moveWithSanDecoder)
        |> required "winner" (Json.Decode.nullable Player.decode)
        |> required "black_captured_pieces" (Json.Decode.list pieceDecoder)
        |> required "white_captured_pieces" (Json.Decode.list pieceDecoder)
        |> Json.Decode.andThen validateDecodedState


type alias RawServerGameState =
    { board : String
    , status : String
    , playerToMove : Player
    , yourPlayer : Player
    , legalMoves : List Move
    , history : History
    , winner : Maybe Player
    , blackCapturedPieces : List Piece
    , whiteCapturedPieces : List Piece
    }


pieceDecoder : Decoder Piece
pieceDecoder =
    Json.Decode.string
        |> Json.Decode.andThen
            (\s ->
                case String.toList s of
                    [ c ] ->
                        case Piece.fromChar c of
                            Just piece ->
                                Json.Decode.succeed piece

                            Nothing ->
                                Json.Decode.fail ("Unable to decode piece from string " ++ s)

                    _ ->
                        Json.Decode.fail ("I was trying to decode a piece when I found a string with length > 1: " ++ s)
            )


validateDecodedState : RawServerGameState -> Decoder ServerGameState
validateDecodedState state =
    let
        newStatusResult =
            case ( state.status, state.winner ) of
                ( "continue", Nothing ) ->
                    Ok Continue

                ( "continue", Just winner ) ->
                    Err ("Inconsistency in state from server: status is Continue, but winner is " ++ Player.toString winner)

                ( "resignation", Just winner ) ->
                    Ok (Over (Resignation winner))

                ( "resignation", Nothing ) ->
                    Err "Inconsistency in state from server: status is resigned, but winner is null"

                ( "checkmate", Just winner ) ->
                    Ok (Over (Mate winner))

                ( "checkmate", Nothing ) ->
                    Err "Inconsistency in state from server: status is checkmate, but winner is null"

                _ ->
                    Err "Unknown status response"
    in
    case newStatusResult of
        Ok newStatus ->
            Json.Decode.succeed
                { board = state.board
                , status = newStatus
                , playerToMove = state.playerToMove
                , yourPlayer = state.yourPlayer
                , legalMoves = state.legalMoves
                , history = state.history
                , blackCapturedPieces = state.blackCapturedPieces
                , whiteCapturedPieces = state.whiteCapturedPieces
                }

        Err message ->
            Json.Decode.fail message


moveDecoder : Decoder { start : String, end : String }
moveDecoder =
    Json.Decode.map2 (\start end -> { start = start, end = end })
        (field "start" string)
        (field "end" string)


moveWithSanDecoder : Decoder MoveWithSan
moveWithSanDecoder =
    Json.Decode.map3 MoveWithSan
        (field "start" string)
        (field "end" string)
        (field "san" string)


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
            (Element.column
                [ Element.width Element.fill ]
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
                        [ drawCommonGameItems data selectablePieces selectableMoves
                        , Element.text reasonText
                        ]

                    WaitingForInitialization ->
                        [ Element.text "waiting for state from backend" ]

                    MyTurn data ->
                        [ drawCommonGameItems data selectablePieces selectableMoves
                        , resignButton
                        ]

                    WaitingForMoveToBeAccepted data ->
                        [ drawCommonGameItems data selectablePieces selectableMoves
                        , Element.text "waiting"
                        , resignButton
                        ]

                    OtherPlayersTurn data ->
                        [ drawCommonGameItems data selectablePieces selectableMoves
                        , Element.text "waiting for other player to move"
                        , resignButton
                        ]
                )
            )
        ]
    }


drawCommonGameItems : CommonModelData a -> ( Set Square, Square -> Msg ) -> ( Set Square, Square -> Msg ) -> Element Msg
drawCommonGameItems data selectablePieces selectableMoves =
    Element.column
        [ Element.width Element.fill ]
        [ history data.history
        , drawCapturedPieces data.otherPlayerLostPieces
        , Board.drawFromFen data.board selectablePieces selectableMoves data.mySide (Element.text ("Error parsing FEN: " ++ data.board))
        , drawCapturedPieces data.myLostPieces
        ]


resignButton : Element Msg
resignButton =
    Element.Input.button
        [ Element.Background.color (Element.rgb255 200 200 200)
        , Element.padding 5
        , Border.rounded 10
        ]
        { onPress = Just Resign, label = Element.text "Offer resignation" }


drawCapturedPieces : List Piece -> Element Msg
drawCapturedPieces pieces =
    List.map Piece.toIconString pieces
        |> List.sort
        |> String.join ""
        |> Element.text


history : History -> Element Msg
history hist =
    List.map .san hist
        |> List.map Element.text
        |> List.map (Element.el [ Element.Background.color (Element.rgb255 128 128 128), Element.padding 5 ])
        |> Element.row [ Element.spacing 5 ]
