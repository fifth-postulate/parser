# elm/parser

---

<img src="image/We_Can_Do_It!.jpg" height="480px">

???

# Elm Netherlands needs you
## We are interested in Elm
## We like to meetup
## Share!

---

# Parsing

A [parser](https://en.wikipedia.org/wiki/Parsing) is a

> software component that takes input data (frequently text) and builds a data structure – often some kind of parse tree, abstract syntax tree or other hierarchical structure, giving a structural representation of the input while checking for correct syntax. 


<section class="parsing-definition">
<a href="https://openclipart.org/detail/237988/file-or-document-icon"><img id="input" src="https://openclipart.org/download/237988/text70.svg" /></a>
<a href="https://openclipart.org/detail/193052/simple-right-arrow"><img id="transform" src="https://openclipart.org/download/193052/arrowright.svg" /></a>
<a href="https://openclipart.org/detail/133363/ontology"><img id="output" src="https://openclipart.org/download/133363/Ontology.svg" /></a>
</section>

???

# Parsing
## From input to output
## Input usually String
## But `elm/bytes` is around the corner
## Output anything you want
## Can fail!

---

# How to create a Parser?

* Adhoc
* Hand Written
* Parser Generator
* Parser Combinator

???

# Various Ways
# No silver bullet
# Pick the right tool
# Stick around for some tips and tricks

---

# Adhoc
## Problem
> Parse a comma separated string of integers into a list of integers

```plain
51,37,14,23,9,5,4,1
```

--

```elm
type alias Input = 
    String
```

--

```elm
type alias Output = 
    List Int
```

--

```elm
type Error
    = NotANumber String
```

???

# Simple format
# Comma separated
# Same structure
# Core functions suffices

---

```elm
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
```

???

# Entire parser
# Most of the code is plumbing

---

[![asciicast](https://asciinema.org/a/210229.svg)](https://asciinema.org/a/210229?size=big)

---

# Hand Written
## Problem
> Parse a comma separated string of **temperature measurements** into a list of temperatures

```plain
19C, 66F ,20C , 68F,20C, 70F,21C
```

--

```elm
type alias Input = 
    String
```

--

```elm
type alias Output = 
    List Temperature

type Temperature
    = Celcius Int
    | Fahrenheit Int
```

???

# mostly simple format
# Comma separated but with whitespace
# Similar structure
# Adhoc could work
# But what if measurements in Kelvin


---

# Methods

1. Define **tokens**; units that you want to parse.
2. Create a **tokenizer**.
3. Write parse functions that consume tokens.

???

# Tokens are **numbers, spaces, commas, celcius scale, fahrenheit scale**
# Chop up `String` to `List Char`
# Goble up `Char`s to make Tokens

---

# Tokens

```elm
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
```

???

# Tokens need to know where they come from
# Mainly for Error reporting
# Different types
# Correspond with characters to expect

---

# `tokenize`

```elm
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

```

???

# Pattern match on characters
# Consume characters that fit the description

---

# parse functions

```elm
parseTokens : List Token -> Result Error (List Temperature)
parseTokens tokens =
    let
        nonWhitespaceTokens =
            tokens
                |> List.filter (\t -> not <| isWhitespaceToken t)
    in
    case nonWhitespaceTokens of
        [] ->
            empty

        _ ->
            temperatureMeasurements nonWhitespaceTokens

temperatureMeasurement : List Token -> ( Result Error Temperature, List Token )
temperatureMeasurement tokens =
    case tokens of
        [] ->
            ( Err <| Parse <| UnexpectedEndOfInput, tokens )

        ({ tokenType, start, finish } as t) :: ts ->
            case tokenType of
                Number n ->
                    let
                        ( scale, tail ) =
                            temperatureScale ts

                        temperature =
                            scale
                                |> Result.map (\fc -> fc n)
                    in
                    ( temperature, tail )

                _ ->
                    ( Err <| Parse <| UnexpectedToken t, ts )
```

???

# Remove whitespace tokens
# Create a function that parses token
# Input is `List token`
# Output is `(Result Error T, List Tokens)`
## Datastructure you are interested in
## Remaining Tokens to Parse

---

[![asciicast](https://asciinema.org/a/210277.svg)](https://asciinema.org/a/210277?size=big)

---

# Parser Generator

???

# Describe tokens & grammar in a external Domain Specific Language
# Use a tool that generates parser code
# Hook into provided mechanism
# Objections
## Depend on the tool
## Needs to play nice with language and infrastructure
## Usually not worth the hassle in expressive languages

---

# Parser Combinators

A [parser combinator](https://en.wikipedia.org/wiki/Parser_combinator) is a

>  higher-order function that accepts several parsers as input and returns a new parser as its output. In this context, a parser is a function accepting strings as input and returning some structure as output, typically a parse tree or a set of indices representing locations in the string where parsing stopped successfully. Parser combinators enable a recursive descent parsing strategy that facilitates modular piecewise construction and testing.

???

# Relies on higher order functions
# Uses function composition
# Easily testable

---

# `elm/parser`

--

```elm
type alias Parser a

run : Parser a -> String -> Result Error a
```

--

## Building Block

```elm
float : Parser Int
symbol : String -> Parser ()
spaces : Parser ()
```

--

## Pipeline

```elm
succeed : a -> Parser a
(|=) : Parser (a -> b) -> Parser a -> Parser b
(|.) : Parser keep -> Parser ignore -> Parser keep
```

???

# Parser library
# Parser combinator
# `Parser a` is a parser that can
## Consume a `String`
## Produces `Result Error a`
# Numerous building blocks
# Various combinators

---

# `Point` Example

## Problem
> Parse the following into `Point` data structure

```
(10, 5)
```

--

```elm
type alias Point = { x : Float, y : Float }
```

--

```elm
point : Parser Point
point =
  succeed Point
    |. symbol "("
    |. spaces
    |= float
    |. spaces
    |. symbol ","
    |. spaces
    |= float
    |. spaces
    |. symbol ")"
```

---

# `elm/parser`

## Problem

> You have a planning problem defined as multiple records of teachers, groups and students, all as a huge, comma separated values format


```plain
GROUP, 28, "Math", 3, 5
GROUP, 37, "Biology", 4, 3
GROUP, 51, "Physics", 2, 8
TEACHER, "Alice", "Math", "Biology"
TEACHER, "Belinda", "Physics"
STUDENT, 1729, 37, 51
STUDENT, 3435, 51
STUDENT, 1024, 28, 37, 51
```

---

# Summary

<table>
  <thead>
    <tr><th>Parser Type</th><th>Complexity</th><th>Lines of Code</th></tr>
  </thead>
  <tbody>
    <tr>
      <td>Adhoc</td>
      <td>Meh</td>
      <td>55</td>
    </tr>
    <tr>
      <td>Hand written</td>
      <td>Considerable</td>
      <td>286</td>
    </tr>
    <tr>
      <td>Combinator</td>
      <td></td>
      <td></td>
    </tr>
  </tbody>
</table>

---

## Attributions

* **We Can Do It!** -- By J. Howard Miller (1918–2004), artist employed by Westinghouse, poster used by the War Production Co-ordinating Committee - From scan of copy belonging to the National Museum of American History, Smithsonian Institution, retrieved from the website of the Virginia Historical Society., Public Domain, https://commons.wikimedia.org/w/index.php?curid=5249733
* **file or document icon** -- https:://openclipart.org/detail/237988/file-or-document-icon
* **simple right arrow** -- https://openclipart.org/detail/193052/simple-right-arrow 
* **Ontology** -- https://openclipart.org/detail/133363/ontology
