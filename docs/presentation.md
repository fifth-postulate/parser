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

---

# How to create a Parser?

* Adhoc
* Hand Written
* Parser Generator
* Parser Combinator

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

---

[![asciicast](https://asciinema.org/a/210229.svg)](https://asciinema.org/a/210229**

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

---

## Attributions

* **We Can Do It!** -- By J. Howard Miller (1918–2004), artist employed by Westinghouse, poster used by the War Production Co-ordinating Committee - From scan of copy belonging to the National Museum of American History, Smithsonian Institution, retrieved from the website of the Virginia Historical Society., Public Domain, https://commons.wikimedia.org/w/index.php?curid=5249733
* **file or document icon** -- https:://openclipart.org/detail/237988/file-or-document-icon
* **simple right arrow** -- https://openclipart.org/detail/193052/simple-right-arrow 
* **Ontology** -- https://openclipart.org/detail/133363/ontology
