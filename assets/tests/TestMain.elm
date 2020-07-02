module TestMain exposing (..)

import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int, list, string)
import Main
import Test exposing (..)


suite : Test
suite =
    describe "replaceNumbers"
        [ test "replace 8" <|
            \_ ->
                Expect.equal "________" (Main.replaceNumbers "" "8")
        , test "replace around" <|
            \_ ->
                Expect.equal "___P____" (Main.replaceNumbers "" "3P4")
        , test "No replacements" <|
            \_ ->
                Expect.equal "pppppppp" (Main.replaceNumbers "" "pppppppp")
        ]
