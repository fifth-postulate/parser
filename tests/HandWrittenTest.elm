module HandWrittenTest exposing (suite)

import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int, list, string)
import Parser.HandWritten exposing (Temperature(..), parse)
import Test exposing (..)


suite : Test
suite =
    describe "Parser"
        [ describe "HandWritten"
            [ describe "parse"
                [ test "empty string" <|
                    \_ ->
                        let
                            actual =
                                parse ""

                            expected =
                                Ok []
                        in
                        Expect.equal actual expected
                , test "single measurement" <|
                    \_ ->
                        let
                            actual =
                                parse "37C"

                            expected =
                                Ok [ Celcius 37 ]
                        in
                        Expect.equal actual expected
                , test "multiple measurements" <|
                    \_ ->
                        let
                            actual =
                                parse "37C,51F"

                            expected =
                                Ok [ Celcius 37, Fahrenheit 51 ]
                        in
                        Expect.equal actual expected
                , test "multiple measurements with spaces" <|
                    \_ ->
                        let
                            actual =
                                parse "37C, 51F ,28C , 60F"

                            expected =
                                Ok [ Celcius 37, Fahrenheit 51, Celcius 28, Fahrenheit 60 ]
                        in
                        Expect.equal actual expected
                ]
            ]
        ]
