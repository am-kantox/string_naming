# StringNaming

**Compile-time generated set of modules to ease an access to a predefined subset of UTF8 symbols.**

## Installation

```elixir
def deps do
  [{:string_naming, "~> 0.7"}]
end
```

## Warning

**The initial compilation of the module in the default configuration takes ≈ 10 sec.**

The compilation of the whole UTF8 symbol set requires ≈ 10 min.

## `config/confix.exs`

The configuration of what is to be compiled could be changed accordingly to
what might be found in [default config](https://github.com/am-kantox/string_naming/blob/master/config/config.exs).
Basically, leading `'#'` and `'='` in front of group names are treated as comments.

## How it works

The code parses the [`NamesList.txt`](http://www.unicode.org/Public/UCD/latest/ucd/NamesList.txt)
file provided by Consortium. It builds the set of nested modules under `StringNaming`.
Each nested module is granted with `__all__/0` function that returns all the
available symbols in that particular namespace.

```elixir
iex|1 ▶ StringNaming.AnimalSymbols.__all__
[ant: "🐜", bat: "🦇", bird: "🐦", blowfish: "🐡", boar: "🐗",
 bug: "🐛", butterfly: "🦋", cat: "🐈", chicken: "🐔", chipmunk: "🐿",
 cow: "🐄", crab: "🦀", crocodile: "🐊", deer: "🦌", dog: "🐕",
 dolphin: "🐬", dragon: "🐉", duck: "🦆", eagle: "🦅", elephant: "🐘",
 fish: "🐟", goat: "🐐", gorilla: "🦍", honeybee: "🐝", horse: "🐎",
 koala: "🐨", leopard: "🐆", lizard: "🦎", monkey: "🐒", mouse: "🐁",
 octopus: "🐙", owl: "🦉", ox: "🐂", penguin: "🐧", pig: "🐖",
 poodle: "🐩", rabbit: "🐇", ram: "🐏", rat: "🐀", rhinoceros: "🦏",
 rooster: "🐓", scorpion: "🦂", shark: "🦈", sheep: "🐑",
 shrimp: "🦐", snail: "🐌", snake: "🐍", spider: "🕷", squid: "🦑",
 tiger: "🐅", ...]
iex|2 ▶ StringNaming.AnimalSymbols.monkey
"🐒"
```

## Changelog

#### `0.7.0` 

**¡NB!** for Elixir < v1.10, use `v0.6.0`

* Added all ASCII set
* Allowed grepping by functions
* Updated `NamesList.txt` (v13 → v14)

#### `0.6.0`

Updated `NamesList.txt` (v9 → v13)

#### `0.4.0`

Added `StringNaming.graphemes/1` function that receives a regular expression and
returns the list of matched characters:

```elixir
iex> StringNaming.graphemes ~r/\Aspace/i
[
  space_medium_mathematical_space: " ",
  spaces_em_quad: " ",
  spaces_em_space: " ",
  spaces_en_quad: " ",
  spaces_en_space: " ",
  spaces_figure_space: " ",
  spaces_four_per_em_space: " ",
  spaces_hair_space: " ",
  spaces_punctuation_space: " ",
  spaces_six_per_em_space: " ",
  spaces_thin_space: " ",
  spaces_three_per_em_space: " "
]
```

## Is it of any good?

Sure it is.

---

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/string_naming](https://hexdocs.pm/string_naming).
