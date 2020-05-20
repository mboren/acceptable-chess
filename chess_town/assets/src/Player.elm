module Player exposing (..)

import Json.Decode exposing (Decoder, string, succeed)


type Player
    = White
    | Black


other : Player -> Player
other player =
    case player of
        White ->
            Black

        Black ->
            White


toString : Player -> String
toString player =
    case player of
        White ->
            "White"

        Black ->
            "Black"


decode : Decoder Player
decode =
    string |> Json.Decode.andThen decoderHelp


decoderHelp s =
    case s of
        "white" ->
            succeed White

        "black" ->
            succeed Black

        _ ->
            Json.Decode.fail ("Not white or black: " ++ s)
