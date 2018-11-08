module ElmParserTest exposing (suite)

import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int, list, string)
import Parser exposing (run)
import Parser.ElmParser exposing (Record(..), group, line, parse, records, student, teacher)
import Test exposing (..)


suite : Test
suite =
    describe "Parser"
        [ describe "`elm/parser`"
            [ describe "student"
                [ test "1729, 37, 51" <|
                    \_ ->
                        let
                            actual =
                                run student "1729, 37, 51;"

                            expected =
                                Ok { identity = 1729, memberships = [ 37, 51 ] }
                        in
                        Expect.equal actual expected
                ]
            , describe "teacher"
                [ test "\"Alice\", \"Math\", \"Biology\"" <|
                    \_ ->
                        let
                            actual =
                                run teacher "\"Alice\", \"Math\", \"Biology\";"

                            expected =
                                Ok { identity = "Alice", capabilities = [ "Math", "Biology" ] }
                        in
                        Expect.equal actual expected
                ]
            , describe "group"
                [ test "28, \"Math\", 3, 5" <|
                    \_ ->
                        let
                            actual =
                                run group "28, \"Math\", 3, 5"

                            expected =
                                Ok { identity = 28, subject = "Math", level = 3, lessonsNeeded = 5 }
                        in
                        Expect.equal actual expected
                ]
            , describe "line" <|
                List.map lineTest
                    [ "GROUP, 28, \"Math\", 3, 5"
                    , "TEACHER, \"Alice\", \"Math\", \"Biology\";"
                    , "STUDENT, 1729, 37, 51;"
                    ]
            , describe "records"
                [ test "GROUP, TEACHER, STUDENT" <|
                    \_ ->
                        let
                            input =
                                [ "GROUP, 28, \"Math\", 3, 5"
                                , "TEACHER, \"Alice\", \"Math\", \"Biology\";"
                                , "STUDENT, 1729, 37, 51;"
                                ]
                                    |> List.map (\s -> s ++ "\n")
                                    |> String.join ""

                            actual =
                                run records input

                            expected =
                                Ok
                                    [ GroupRecord { identity = 28, subject = "Math", level = 3, lessonsNeeded = 5 }
                                    , TeacherRecord { identity = "Alice", capabilities = [ "Math", "Biology" ] }
                                    , StudentRecord { identity = 1729, memberships = [ 37, 51 ] }
                                    ]
                        in
                        Expect.equal expected actual
                ]
            ]
        ]


lineTest : String -> Test
lineTest aLine =
    test aLine <|
        \_ ->
            let
                actual =
                    run line aLine

                isOk result =
                    case result of
                        Ok _ ->
                            True

                        Err _ ->
                            False
            in
            Expect.true (aLine ++ " parsed incorrectly") <| isOk actual
