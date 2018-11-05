module Parser.HandWritten exposing (Error, Input, Output, Temperature(..), parse, tokenize)

{-| A demonstration of hand written parser.


# Input

A `String` of comma separeted values, specifically temperature measurements.

```plain
19C, 66F ,20C , 68F,20C, 70F,21C
```


# Output

A `List Temperature`

-}


type alias Input =
    String


type alias Output =
    List Temperature


type Temperature
    = Celcius Int
    | Fahrenheit Int


type Error
    = Tokenize TokenizeError
    | Parse ParseError


type TokenizeError
    = UnknownCharacter Char
    | NotANumber String


type ParseError
    = UnexpectedToken Token
    | UnexpectedEndOfInput
    | NotImplemented


type alias Token =
    { tokenType : TokenType
    , start : Int
    , finish : Int
    }


type TokenType
    = Number Int
    | TemperatureScale Scale
    | Comma
    | Whitespace String


type alias Scale =
    Int -> Temperature

parse : Input -> Result Error Output
parse input =
    let
        characters =
            input
                |> String.toList
    in
    characters
        |> tokenize
        |> Result.andThen parseTokens


tokenize : List Char -> Result Error (List Token)
tokenize characters =
    tokenizeWithIndex 0 characters


tokenizeWithIndex : Int -> List Char -> Result Error (List Token)
tokenizeWithIndex index characters =
    case characters of
        [] ->
            Ok []

        c :: cs ->
            let
                consTo : Result Error (List Token) -> Token -> Result Error (List Token)
                consTo tail token =
                    tail
                        |> Result.map (\t -> token :: t)
            in
            case c of
                ',' ->
                    Token Comma index (index + 1)
                        |> consTo (tokenizeWithIndex (index + 1) cs)

                'C' ->
                    Token (TemperatureScale Celcius) index (index + 1)
                        |> consTo (tokenizeWithIndex (index + 1) cs)

                'F' ->
                    Token (TemperatureScale Fahrenheit) index (index + 1)
                        |> consTo (tokenizeWithIndex (index + 1) cs)

                ' ' ->
                    let
                        ( whitespace, tail ) =
                            chompWhile isSpace characters

                        length =
                            String.length whitespace
                    in
                    Token (Whitespace whitespace) index (index + length)
                        |> consTo (tokenizeWithIndex (index + length) tail)

                _ ->
                    if isDigit c then
                        let
                            ( digits, tail ) =
                                chompWhile isDigit characters

                            length =
                                String.length digits
                        in
                        digits
                            |> String.toInt
                            |> Result.fromMaybe (Tokenize (NotANumber digits))
                            |> Result.andThen
                                (\n ->
                                    Token (Number n) index (index + length)
                                        |> consTo (tokenizeWithIndex (index + length) tail)
                                )

                    else
                        Err <| Tokenize <| UnknownCharacter c


chompWhile : (Char -> Bool) -> List Char -> ( String, List Char )
chompWhile predicate characters =
    let
        ( found, tail ) =
            chompWhileWith [] predicate characters

        result =
            found
                |> List.reverse
                |> String.fromList
    in
    ( result, tail )


chompWhileWith : List Char -> (Char -> Bool) -> List Char -> ( List Char, List Char )
chompWhileWith accumulator predicate characters =
    case characters of
        [] ->
            ( accumulator, [] )

        c :: cs ->
            if predicate c then
                chompWhileWith (c :: accumulator) predicate cs

            else
                ( accumulator, characters )


isSpace : Char -> Bool
isSpace character =
    character == ' '


isDigit : Char -> Bool
isDigit character =
    let
        code =
            Char.toCode character
    in
    48 <= code && code <= 57


parseTokens : List Token -> Result Error (List Temperature)
parseTokens tokens =
    case tokens of
        [] ->
            empty

        _ ->
            temperatureMeasurements tokens


empty : Result Error (List Temperature)
empty =
    Ok <| []


temperatureMeasurements : List Token -> Result Error (List Temperature)
temperatureMeasurements tokens =
    case tokens of
        [] ->
            Err <| Parse <| UnexpectedEndOfInput

        _ ->
            let
                ( measurement, tail ) =
                    temperatureMeasurement tokens
            in
            case tail of
                [] ->
                    measurement
                        |> Result.map (\m -> [m])


                ({ tokenType, start, finish } as t) :: ts ->
                    case tokenType of
                        Comma ->
                            measurement
                                |> Result.andThen
                                    (\m ->
                                        let
                                            rest =
                                                temperatureMeasurements ts
                                        in
                                        rest
                                            |> Result.map (\ms -> (m :: ms))
                                    )

                        _ ->
                            Err <| Parse <| UnexpectedToken t

temperatureMeasurement : List Token -> (Result Error Temperature, List Token)
temperatureMeasurement tokens =
    case tokens of
        [] ->
            (Err <| Parse <| UnexpectedEndOfInput, tokens)

        ({ tokenType, start, finish } as t) :: ts ->
            case tokenType of
                Number n ->
                    let
                        (scale, tail) = temperatureScale ts

                        temperature =
                            scale
                                |> Result.map (\fc -> fc n)
                    in
                        (temperature, tail)

                _ ->
                    (Err <| Parse <| UnexpectedToken t, ts)

temperatureScale : List Token -> (Result Error Scale, List Token)
temperatureScale tokens =
    case tokens of
        [] ->
            (Err <| Parse <| UnexpectedEndOfInput, tokens)

        ({ tokenType, start, finish } as t) :: ts ->
            case tokenType of
                TemperatureScale scale ->
                    (Ok scale, ts)

                _ ->
                    (Err <| Parse <| UnexpectedToken t, ts)

