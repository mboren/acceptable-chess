module Square exposing (..)

import Set


type alias Square =
    String


lightSquares =
    Set.fromList [ "e6", "c8", "h7", "c4", "b1", "h3", "d7", "f3", "b7", "f1", "a4", "b3", "c6", "e4", "b5", "h1", "d1", "d3", "f7", "e8", "g6", "g4", "g8", "a6", "c2", "d5", "g2", "a2", "e2", "a8", "f5", "h5" ]


darkSquares =
    Set.fromList [ "e7", "c7", "d8", "a5", "a7", "e1", "f4", "d2", "g1", "h8", "e3", "g5", "g7", "a3", "b8", "h4", "f8", "e5", "h2", "f2", "a1", "b4", "d4", "c3", "h6", "g3", "c1", "f6", "c5", "b2", "d6", "b6" ]


isLight square =
    Set.member square lightSquares
