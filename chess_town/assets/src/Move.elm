module Move exposing (..)

import Square exposing (Square)


type alias Move =
    { start : Square, end : Square }