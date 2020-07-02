port module Main exposing (..)

import Board
import Browser exposing (Document)
import Browser.Dom as Dom
import Browser.Events
import Element exposing (Element)
import Element.Background
import Element.Border as Border
import Element.Font as Font
import Element.Input
import History exposing (History)
import Html.Attributes
import Json.Decode exposing (Decoder, field, string)
import Move exposing (Move, MoveWithSan, MoveWithStringPromotion)
import Piece exposing (Piece)
import Player exposing (Player)
import Set exposing (Set)
import Square exposing (Square)
import Task
import Time


port sendMessage : String -> Cmd msg


port sendMove : MoveWithStringPromotion -> Cmd msg


port messageReceiver : (Json.Decode.Value -> msg) -> Sub msg


maxWidth =
    700


historyId =
    "history"


type alias Model =
    { gameModel : GameModel
    , innerWidth : Int
    , innerHeight : Int
    , joinUrl : String
    }


type GameModel
    = WaitingForInitialization
    | WaitingForPlayerToJoin Time.Posix
    | MyTurn
        { mySide : Player
        , myLostPieces : List Piece
        , otherPlayerLostPieces : List Piece
        , legalMoves : List Move
        , board : String
        , history : History MoveWithSan
        , selection : Selection
        }
    | WaitingForMoveToBeAccepted
        { mySide : Player
        , myLostPieces : List Piece
        , otherPlayerLostPieces : List Piece
        , legalMoves : List Move
        , board : String
        , history : History MoveWithSan
        , moveSent : Move
        }
    | OtherPlayersTurn
        { mySide : Player
        , myLostPieces : List Piece
        , otherPlayerLostPieces : List Piece
        , board : String
        , history : History MoveWithSan
        }
    | GameOver
        { mySide : Player
        , myLostPieces : List Piece
        , otherPlayerLostPieces : List Piece
        , board : String
        , history : History MoveWithSan
        , reason : GameOverReason
        }


type alias CommonModelData a =
    { a
        | history : History MoveWithSan
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
    | SelectingPromotion Square Square (List Piece)


type ServerGameStatus
    = Continue
    | Over GameOverReason


type alias ServerGameState =
    { board : String
    , status : ServerGameStatus
    , playerToMove : Player
    , yourPlayer : Player -- TODO I don't like this naming
    , legalMoves : List Move
    , history : History MoveWithSan
    , blackCapturedPieces : List Piece
    , whiteCapturedPieces : List Piece
    , bothPlayersConnected : Bool
    }


type Emotion
    = Neutral
    | Thinking
    | Victorious
    | Despondent


init : { innerWidth : Int, innerHeight : Int, joinUrl : String } -> ( Model, Cmd Msg )
init { innerWidth, innerHeight, joinUrl } =
    ( Model WaitingForInitialization innerWidth innerHeight joinUrl, sendMessage "ready" )


main : Program { innerWidth : Int, innerHeight : Int, joinUrl : String } Model Msg
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
    | PromotionSelected Piece
    | Resign
    | WindowResized Int Int
    | NoOp
    | AnimationFrame Time.Posix
    | CancelPromotion
    | RestartGame


updateGameModel : Model -> GameModel -> Model
updateGameModel model newGameModel =
    { model | gameModel = newGameModel }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        CancelPromotion ->
            case model.gameModel of
                MyTurn data ->
                    case data.selection of
                        SelectingPromotion start _ _ ->
                            let
                                newData =
                                    { data | selection = SelectingEnd start }
                            in
                            ( updateGameModel model (MyTurn newData), Cmd.none )

                        _ ->
                            ( model, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        AnimationFrame time ->
            case model.gameModel of
                WaitingForPlayerToJoin _ ->
                    ( updateGameModel model (WaitingForPlayerToJoin time), Cmd.none )

                _ ->
                    ( model, Cmd.none )

        WindowResized width height ->
            ( { model | innerWidth = width, innerHeight = height }, Cmd.none )

        NewSelectedMoveStart square ->
            case model.gameModel of
                MyTurn data ->
                    ( updateGameModel model (MyTurn { data | selection = SelectingEnd square }), Cmd.none )

                _ ->
                    ( model, Cmd.none )

        NewSelectedMoveEnd end ->
            case model.gameModel of
                MyTurn data ->
                    case data.selection of
                        SelectingEnd start ->
                            case Move.getPossiblePromotions data.legalMoves start end of
                                [] ->
                                    let
                                        move =
                                            Move start end Nothing
                                    in
                                    ( updateGameModel model
                                        (WaitingForMoveToBeAccepted
                                            { mySide = data.mySide
                                            , myLostPieces = data.myLostPieces
                                            , otherPlayerLostPieces = data.otherPlayerLostPieces
                                            , legalMoves = data.legalMoves
                                            , board = data.board
                                            , history = data.history
                                            , moveSent = move
                                            }
                                        )
                                    , sendMove { start = move.start, end = move.end, promotion = Nothing }
                                    )

                                promotions ->
                                    let
                                        promotionPieces =
                                            List.map (\kind -> Piece kind data.mySide) promotions
                                    in
                                    ( updateGameModel model
                                        (MyTurn { data | selection = SelectingPromotion start end promotionPieces })
                                    , Cmd.none
                                    )

                        _ ->
                            ( model, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        PromotionSelected piece ->
            case model.gameModel of
                MyTurn data ->
                    case data.selection of
                        SelectingPromotion start end _ ->
                            let
                                move =
                                    Move start end (Just piece.kind)
                            in
                            ( updateGameModel model
                                (WaitingForMoveToBeAccepted
                                    { mySide = data.mySide
                                    , myLostPieces = data.myLostPieces
                                    , otherPlayerLostPieces = data.otherPlayerLostPieces
                                    , legalMoves = data.legalMoves
                                    , board = data.board
                                    , history = data.history
                                    , moveSent = move
                                    }
                                )
                            , sendMove { start = move.start, end = move.end, promotion = Just <| Piece.pieceKindToString piece.kind }
                            )

                        _ ->
                            ( model, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        Resign ->
            ( model, sendMessage "resign" )

        RestartGame ->
            ( model, sendMessage "restart" )

        GetState value ->
            case Json.Decode.decodeValue boardStateDecoder value of
                Err err ->
                    let
                        _ =
                            Json.Decode.errorToString err |> Debug.log "error"
                    in
                    ( model, Cmd.none )

                Ok state ->
                    if not state.bothPlayersConnected then
                        ( updateGameModel model (WaitingForPlayerToJoin (Time.millisToPosix 0))
                        , Cmd.none
                        )

                    else
                        let
                            command =
                                if state.history /= getHistory model.gameModel then
                                    scrollRight historyId

                                else
                                    Cmd.none
                        in
                        case state.status of
                            Over reason ->
                                case reason of
                                    Mate winner ->
                                        ( updateGameModel model
                                            (GameOver
                                                { mySide = state.yourPlayer
                                                , myLostPieces = getLostPieces state.yourPlayer state
                                                , otherPlayerLostPieces = getLostPieces (Player.other state.yourPlayer) state
                                                , board = state.board
                                                , history = state.history
                                                , reason = Mate winner
                                                }
                                            )
                                        , command
                                        )

                                    Resignation winner ->
                                        ( updateGameModel model
                                            (GameOver
                                                { mySide = state.yourPlayer
                                                , myLostPieces = getLostPieces state.yourPlayer state
                                                , otherPlayerLostPieces = getLostPieces (Player.other state.yourPlayer) state
                                                , board = state.board
                                                , history = state.history
                                                , reason = Resignation winner
                                                }
                                            )
                                        , command
                                        )

                            Continue ->
                                let
                                    selection =
                                        case model.gameModel of
                                            MyTurn data ->
                                                data.selection

                                            _ ->
                                                SelectingStart

                                    newModel =
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
                                ( updateGameModel model newModel, command )


getEmotions : GameModel -> ( Emotion, Emotion )
getEmotions gameModel =
    case gameModel of
        WaitingForInitialization ->
            ( Neutral, Neutral )

        WaitingForPlayerToJoin _ ->
            ( Neutral, Neutral )

        MyTurn data ->
            ( Thinking, Neutral )

        OtherPlayersTurn data ->
            ( Neutral, Thinking )

        WaitingForMoveToBeAccepted data ->
            ( Thinking, Neutral )

        GameOver data ->
            let
                winner =
                    case data.reason of
                        Mate player ->
                            player

                        Resignation player ->
                            player
            in
            if winner == data.mySide then
                ( Victorious, Despondent )

            else
                ( Despondent, Victorious )


getHistory : GameModel -> History MoveWithSan
getHistory model =
    case model of
        WaitingForInitialization ->
            History.empty

        WaitingForPlayerToJoin _ ->
            History.empty

        MyTurn data ->
            data.history

        OtherPlayersTurn data ->
            data.history

        WaitingForMoveToBeAccepted data ->
            data.history

        GameOver data ->
            data.history


scrollRight : String -> Cmd Msg
scrollRight id =
    Task.attempt (\_ -> NoOp)
        (Dom.getViewportOf id
            |> Task.andThen
                (\vp ->
                    Dom.setViewportOf id vp.scene.width 0
                        |> Task.onError (\_ -> Task.succeed ())
                )
        )


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
        |> required "history"
            (Json.Decode.list moveWithSanDecoder
                |> Json.Decode.andThen (List.reverse >> History.fromList >> Json.Decode.succeed)
            )
        |> required "winner" (Json.Decode.nullable Player.decode)
        |> required "black_captured_pieces" (Json.Decode.list pieceDecoder)
        |> required "white_captured_pieces" (Json.Decode.list pieceDecoder)
        |> required "both_players_connected" Json.Decode.bool
        |> Json.Decode.andThen validateDecodedState


type alias RawServerGameState =
    { board : String
    , status : String
    , playerToMove : Player
    , yourPlayer : Player
    , legalMoves : List Move
    , history : History MoveWithSan
    , winner : Maybe Player
    , blackCapturedPieces : List Piece
    , whiteCapturedPieces : List Piece
    , bothPlayersConnected : Bool
    }


promotionDecoder : Decoder Piece.PieceKind
promotionDecoder =
    Json.Decode.string
        |> Json.Decode.andThen
            (\s ->
                case String.toList s of
                    [ c ] ->
                        let
                            pieceKind =
                                case c of
                                    'q' ->
                                        Just Piece.Queen

                                    'n' ->
                                        Just Piece.Knight

                                    'b' ->
                                        Just Piece.Bishop

                                    'r' ->
                                        Just Piece.Rook

                                    _ ->
                                        Nothing
                        in
                        pieceKind
                            |> Maybe.map Json.Decode.succeed
                            |> Maybe.withDefault (Json.Decode.fail ("Unable to decode promotion from string " ++ s))

                    _ ->
                        Json.Decode.fail ("I was trying to decode a promotion when I found a string with length > 1: " ++ s)
            )


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
                , bothPlayersConnected = state.bothPlayersConnected
                }

        Err message ->
            Json.Decode.fail message


moveDecoder : Decoder { start : String, end : String, promotion : Maybe Piece.PieceKind }
moveDecoder =
    Json.Decode.map3 (\start end promotion -> { start = start, end = end, promotion = promotion })
        (field "start" string)
        (field "end" string)
        (Json.Decode.maybe (field "promotion" promotionDecoder))


moveWithSanDecoder : Decoder MoveWithSan
moveWithSanDecoder =
    Json.Decode.map4 MoveWithSan
        (field "start" string)
        (field "end" string)
        (Json.Decode.maybe (field "promotion" promotionDecoder))
        (field "san" string)


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        ([ messageReceiver GetState
         , Browser.Events.onResize WindowResized
         ]
            ++ (case model.gameModel of
                    WaitingForPlayerToJoin _ ->
                        [ Browser.Events.onAnimationFrame AnimationFrame ]

                    _ ->
                        []
               )
        )


getSelectablePieces : List Move -> Set Square
getSelectablePieces moves =
    List.map .start moves
        |> Set.fromList


getPossibleMoveEndsFromSquare : Square -> List Move -> Set Square
getPossibleMoveEndsFromSquare start moves =
    List.filter (\move -> move.start == start) moves
        |> List.map .end
        |> Set.fromList


getRenderData : GameModel -> Board.RenderData Msg
getRenderData model =
    let
        defaultRenderData : Board.RenderData Msg
        defaultRenderData =
            { selectablePieceSquares = Set.empty
            , selectPieceEvent = NewSelectedMoveStart
            , selectableMoveSquares = Set.empty
            , selectMoveEvent = NewSelectedMoveEnd
            , lastPly = Nothing
            }
    in
    case model of
        MyTurn data ->
            let
                lastPly = History.getLastPly data.history
                renderData = {defaultRenderData | lastPly = lastPly}
            in
            case data.selection of
                SelectingStart ->
                    { renderData | selectablePieceSquares = getSelectablePieces data.legalMoves }

                SelectingEnd start ->
                    { renderData | selectablePieceSquares = getSelectablePieces data.legalMoves
                    , selectableMoveSquares = getPossibleMoveEndsFromSquare start data.legalMoves}

                SelectingPromotion _ _ _ ->
                    renderData

        OtherPlayersTurn data ->
            { defaultRenderData | lastPly = History.getLastPly data.history}
        _ ->
            defaultRenderData


view : Model -> Document Msg
view model =
    let
        renderData = getRenderData model.gameModel

        width =
            min model.innerWidth maxWidth

        ( myEmotion, otherPlayerEmotion ) =
            getEmotions model.gameModel
    in
    { title = "chess"
    , body =
        [ Element.layout
            []
            (Element.column
                [ Element.width (Element.fill |> Element.maximum maxWidth)
                , Element.centerX
                ]
                (case model.gameModel of
                    GameOver data ->
                        let
                            reasonText =
                                case data.reason of
                                    Mate winner ->
                                        Player.toString winner ++ " wins!"

                                    Resignation winner ->
                                        Player.toString winner ++ " wins by resignation"
                        in
                        [ drawCommonGameItems width myEmotion otherPlayerEmotion data renderData
                        , Element.text reasonText
                        , restartGameButton
                        ]

                    WaitingForInitialization ->
                        [ Element.text "waiting for state from backend" ]

                    WaitingForPlayerToJoin time ->
                        [ Element.paragraph [] [ Element.text "Send this link to a friend to let them join your game:" ]
                        , Element.el
                            [ Border.rounded 3
                            , Border.color (Element.rgb255 186 189 182)
                            , Border.width 1
                            , Element.padding 10
                            ]
                            (Element.text model.joinUrl)
                        , Element.el [ Element.padding 10 ] (Element.text "Waiting for other player to join....")
                        , spinner time
                        ]

                    MyTurn data ->
                        case data.selection of
                            SelectingPromotion _ _ possiblePromotions ->
                                [ Element.column
                                    [ Element.width Element.fill ]
                                    [ history data.history
                                    , drawPlayerInfo otherPlayerEmotion (Player.toString (Player.other data.mySide)) data.otherPlayerLostPieces
                                    , Board.drawFromFenWithPromotions width data.board data.mySide (History.getLastPly data.history) possiblePromotions PromotionSelected CancelPromotion (Element.text ("Error parsing FEN: " ++ data.board))
                                    , drawPlayerInfo myEmotion (Player.toString data.mySide) data.myLostPieces
                                    ]
                                ]
                            _ ->
                                [ drawCommonGameItems width myEmotion otherPlayerEmotion data renderData
                                , resignButton
                                ]

                    WaitingForMoveToBeAccepted data ->
                        [ drawCommonGameItems width myEmotion otherPlayerEmotion data renderData
                        , Element.text "waiting"
                        , resignButton
                        ]

                    OtherPlayersTurn data ->
                        [ drawCommonGameItems width myEmotion otherPlayerEmotion data renderData
                        , resignButton
                        , Element.text "waiting for other player to move"
                        ]
                )
            )
        ]
    }


drawCommonGameItems : Int -> Emotion -> Emotion -> CommonModelData a -> Board.RenderData Msg -> Element Msg
drawCommonGameItems innerWidth myEmotion otherPlayerEmotion data renderData =
    Element.column
        [ Element.width Element.fill ]
        [ history data.history
        , drawPlayerInfo otherPlayerEmotion (Player.toString (Player.other data.mySide)) data.otherPlayerLostPieces
        , Board.drawFromFen innerWidth data.board renderData data.mySide (Element.text ("Error parsing FEN: " ++ data.board))
        , drawPlayerInfo myEmotion (Player.toString data.mySide) data.myLostPieces
        ]


drawPlayerInfo : Emotion -> String -> List Piece -> Element Msg
drawPlayerInfo emotion name lostPieces =
    Element.row
        [ Element.spacing 10
        , Element.width Element.fill
        , Element.Background.color (Element.rgb255 150 150 150)
        ]
        [ drawEmotion emotion
        , Element.column []
            [ Element.el [ Font.bold ] (Element.text name)
            , drawCapturedPieces lostPieces
            ]
        ]


drawEmotion : Emotion -> Element Msg
drawEmotion emotion =
    let
        face =
            case emotion of
                Neutral ->
                    "☺️"

                Thinking ->
                    "\u{1F914}"

                Victorious ->
                    "😎"

                Despondent ->
                    "\u{1F92F}"
    in
    Element.el
        [ Font.size 50
        , Element.padding 5
        , Element.Background.color (Element.rgb255 230 230 230)
        ]
        (Element.text face)


resignButton : Element Msg
resignButton =
    Element.Input.button
        [ Element.Background.color (Element.rgb255 255 90 120)
        , Element.padding 5
        , Border.rounded 10
        , Element.height (Element.px 50)
        , Element.width Element.fill
        , Font.center
        ]
        { onPress = Just Resign, label = Element.text "Resign" }


restartGameButton : Element Msg
restartGameButton =
    Element.Input.button
        [ Element.Background.color (Element.rgb255 200 200 200)
        , Element.padding 5
        , Border.rounded 10
        ]
        { onPress = Just RestartGame, label = Element.text "Rematch" }


drawCapturedPieces : List Piece -> Element Msg
drawCapturedPieces pieces =
    List.map Piece.toIconString pieces
        |> List.sort
        |> List.append [ " " ]
        |> String.join ""
        |> Element.text


history : History MoveWithSan -> Element Msg
history hist =
    let
        renderPly ply =
            Element.el [ Element.Background.color (Element.rgb255 128 128 128), Element.padding 5 ] (Element.text ply.san)

        renderNumber i =
            Element.el [ Element.padding 5 ] (Element.text (String.fromInt i ++ "."))
    in
    History.render renderPly renderNumber hist
        |> Element.row
            [ Element.width Element.fill
            , Element.height (Element.px 50)
            , Element.spacing 5
            , Element.paddingXY 0 0
            , Element.scrollbarX
            , Element.clipY
            , Element.htmlAttribute (Html.Attributes.id historyId)
            , Element.Background.color (Element.rgb255 190 190 190)
            ]


spinner : Time.Posix -> Element Msg
spinner time =
    let
        rotationsPerSecond =
            1.0

        radiansPerMilli =
            rotationsPerSecond * (2.0 * pi / 1000.0)

        radians =
            (Time.posixToMillis time |> toFloat) * radiansPerMilli
    in
    Element.image
        [ Element.width (Element.px 50), Element.rotate radians ]
        { src = Board.pieceToFileName (Piece Piece.Pawn Player.Black), description = "loading spinner" }
