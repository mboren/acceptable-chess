module TestHistory exposing (..)

import Expect exposing (Expectation)
import History
import Test exposing (..)


suite : Test
suite =
    describe "History tests"
        [ describe "History.fromList"
            [ test "empty" <|
                \_ ->
                    Expect.equal History.empty (History.fromList [])
            , test "single item" <|
                \_ ->
                    Expect.equal { pastMoves = [], incompleteMove = Just 1 } (History.fromList [ 1 ])
            , test "two items" <|
                \_ ->
                    Expect.equal { pastMoves = [ ( 1, 2 ) ], incompleteMove = Nothing } (History.fromList [ 1, 2 ])
            , test "three items" <|
                \_ ->
                    Expect.equal { pastMoves = [ ( 1, 2 ) ], incompleteMove = Just 3 } (History.fromList [ 1, 2, 3 ])
            , test "four items" <|
                \_ ->
                    Expect.equal { pastMoves = [ ( 3, 4 ), ( 1, 2 ) ], incompleteMove = Nothing } (History.fromList [ 1, 2, 3, 4 ])
            , test "five items" <|
                \_ ->
                    Expect.equal { pastMoves = [ ( 3, 4 ), ( 1, 2 ) ], incompleteMove = Just 5 } (History.fromList [ 1, 2, 3, 4, 5 ])
            ]
        , describe "History.fromList should be inverse of History.toList"
            [ test "five items" <|
                \_ ->
                    let
                        list =
                            [ 1, 2, 3, 4, 5 ]
                    in
                    Expect.equal (History.toList (History.fromList list)) list
            ]
        , describe "History.getLastPly" <|
            [ test "getLastPly of empty should return Nothing" <|
                \_ ->
                    Expect.equal Nothing (History.getLastPly History.empty)
            , test "single item" <|
                \_ ->
                    Expect.equal (Just 1) (History.getLastPly { pastMoves = [], incompleteMove = Just 1 })
            , test "two items" <|
                \_ ->
                    Expect.equal (Just 2) (History.getLastPly { pastMoves = [ ( 1, 2 ) ], incompleteMove = Nothing })
            , test "three items" <|
                \_ ->
                    Expect.equal (Just 3) (History.getLastPly { pastMoves = [ ( 1, 2 ) ], incompleteMove = Just 3 })


            ]
        ]
