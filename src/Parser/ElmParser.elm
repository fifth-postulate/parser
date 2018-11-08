module Parser.ElmParser exposing (Error, Group, Input, Output, ProblemDefinition, Record(..), Student, Teacher, group, line, parse, records, student, teacher)

{-| A demonstration of `elm/parser` parser.


# Input

```plain
GROUP, 28, "Math", 3, 5
GROUP, 37, "Biology", 4, 3
GROUP, 51, "Physics", 2, 8
TEACHER, "Alice", "Math", "Biology";
TEACHER, "Belinda", "Physics";
STUDENT, 1729, 37, 51;
STUDENT, 3435, 51;
STUDENT, 1024, 28, 37, 51;
```


# Output

A problem definition.

-}

import Parser exposing (..)


type alias Input =
    String


type alias Output =
    ProblemDefinition


type alias Error =
    List DeadEnd


type alias ProblemDefinition =
    { groups : List Group
    , teachers : List Teacher
    , students : List Student
    }


type alias Group =
    { identity : Int
    , subject : String
    , level : Int
    , lessonsNeeded : Int
    }


type alias Teacher =
    { identity : String
    , capabilities : List String
    }


type alias Student =
    { identity : Int
    , memberships : List Int
    }


parse : Input -> Result Error Output
parse input =
    let
        insert : Record -> ProblemDefinition -> ProblemDefinition
        insert rec definition =
            case rec of
                GroupRecord g ->
                    { definition | groups = g :: definition.groups }

                TeacherRecord t ->
                    { definition | teachers = t :: definition.teachers }

                StudentRecord s ->
                    { definition | students = s :: definition.students }

        emptyDefinition =
            { groups = []
            , teachers = []
            , students = []
            }

        toProblemDefinition recs =
            List.foldr insert emptyDefinition recs
    in
    run records input
        |> Result.map toProblemDefinition


type Record
    = GroupRecord Group
    | TeacherRecord Teacher
    | StudentRecord Student


records : Parser (List Record)
records =
    loop [] recordsHelp


recordsHelp : List Record -> Parser (Step (List Record) (List Record))
recordsHelp reverseRecords =
    oneOf
        [ succeed (\aRecord -> Loop (aRecord :: reverseRecords))
            |= line
            |. symbol "\n"
        , succeed ()
            |> map (\_ -> Done (List.reverse reverseRecords))
        ]


line : Parser Record
line =
    let
        header : Parser String
        header =
            succeed identity
                |= oneOf
                    [ map (\_ -> "GROUP") (keyword "GROUP")
                    , map (\_ -> "TEACHER") (keyword "TEACHER")
                    , map (\_ -> "STUDENT") (keyword "STUDENT")
                    , problem "record not of type GROUP, TEACHER or STUDENT"
                    ]
                |. spaces
                |. comma
                |. spaces
    in
    header
        |> andThen record


record : String -> Parser Record
record header =
    case header of
        "GROUP" ->
            map GroupRecord group

        "TEACHER" ->
            map TeacherRecord teacher

        "STUDENT" ->
            map StudentRecord student

        _ ->
            problem <| "Expected record of type GROUP, TEACHER or STUDENT. Got " ++ header


group : Parser Group
group =
    succeed Group
        |= int
        |. spaces
        |. comma
        |. spaces
        |= quotedWord
        |. spaces
        |. comma
        |. spaces
        |= int
        |. spaces
        |. comma
        |. spaces
        |= int


teacher : Parser Teacher
teacher =
    succeed Teacher
        |= quotedWord
        |. spaces
        |. comma
        |. spaces
        |= capabilities


quotedWord : Parser String
quotedWord =
    let
        isQuote c =
            c == '"'

        removeQuotes input _ =
            String.slice 1 -1 input
    in
    mapChompedString removeQuotes <|
        succeed ()
            |. chompIf isQuote
            |. chompUntil "\""
            |. chompIf isQuote


capabilities : Parser (List String)
capabilities =
    sequence
        { start = ""
        , separator = ","
        , end = ";"
        , spaces = spaces
        , item = quotedWord
        , trailing = Parser.Forbidden
        }


student : Parser Student
student =
    succeed Student
        |= int
        |. spaces
        |. comma
        |. spaces
        |= memberships


comma : Parser ()
comma =
    symbol ","


memberships : Parser (List Int)
memberships =
    sequence
        { start = ""
        , separator = ","
        , end = ";"
        , spaces = spaces
        , item = int
        , trailing = Parser.Forbidden
        }
