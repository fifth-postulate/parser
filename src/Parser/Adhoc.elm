module Parser.Adhoc exposing (parse)

{-| A demonstation of adhoc parsing.


# Input

A `String` of comma separated values

```plain
51,37,14,23,9,5,4,1
```


# Output

A `List Int`

-}


type alias Input =
    String


type alias Output =
    List Int


type Error
    = NotANumber String


parse : Input -> Result Error Output
parse input =
    let
        toInt : String -> Result Error Int
        toInt text =
            text
                |> String.toInt
                |> Result.fromMaybe (NotANumber text)

        prependTo : Result Error Output -> Int -> Result Error Output
        prependTo tail head =
            Result.map (\t -> head :: t) tail

        folder : Result Error Int -> Result Error Output -> Result Error Output
        folder head tail =
            head
                |> Result.andThen (prependTo tail)
    in
    input                            -- String
        |> String.split ","          -- List String
        |> List.map toInt            -- List (Result Error Int)
        |> List.foldr folder (Ok []) -- Result Error Output
