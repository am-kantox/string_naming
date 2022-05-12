defmodule StringNaming.H do
  def nested_module(mod, children) do
    [funs, mods] =
      Enum.reduce(children, [%{}, %{}], fn
        {k, v}, [funs, mods] when is_binary(v) -> [Map.put(funs, k, v), mods]
        {k, v}, [funs, mods] -> [funs, Map.put(mods, k, v)]
      end)

    ast =
      for {name, value} <- funs do
        name =
          name |> String.replace(~r/\A(\d)/, "N_\\1") |> Macro.underscore() |> String.to_atom()

        quote do: def(unquote(name)(), do: <<String.to_integer(unquote(value), 16)::utf8>>)
      end ++
        [
          quote do
            def __all__ do
              :functions
              |> __MODULE__.__info__()
              |> Enum.map(fn
                {:__all__, 0} -> nil
                {k, 0} -> {k, apply(__MODULE__, k, [])}
                _ -> nil
              end)
              |> Enum.filter(& &1)
            end
          end
        ]

    Module.create(Module.concat(mod), ast, Macro.Env.location(__ENV__))
    StringNaming.H.nesteds(mod, mods)
  end

  def nesteds(nested \\ [], map_or_code)

  def nesteds(nested, %{} = map) do
    Enum.each(map, fn
      {_key, code} when is_binary(code) ->
        :ok

      {k, v} ->
        mod = :lists.reverse([k | :lists.reverse(nested)])
        StringNaming.H.nested_module(mod, v)
    end)
  end
end

defmodule StringNaming do
  @moduledoc ~S"""
  The sibling of [`String.Casing`](https://github.com/elixir-lang/elixir/blob/9873e4239f063e044e5d6602e173ebee4f32391d/lib/elixir/unicode/properties.ex#L57),
    `String.Break` and `String.Normalizer` from Elixir core.

  It parses the [`NamesList.txt`](http://www.unicode.org/Public/UCD/latest/ucd/NamesList.txt) file provided by Consortium, building
    the set of nested modules under `StringNaming`. Each nested module is granted with `__all__/0` function that returns all the
    available symbols in that particular namespace, as well as with methods returning a symbol by it’s name.

  ## Examples

      iex> StringNaming.AnimalSymbols.monkey
      "🐒"
      iex> StringNaming.FrakturSymbols.Mathematical.Fraktur.Capital.__all__
      [a: "𝔄", b: "𝔅", d: "𝔇", e: "𝔈", f: "𝔉", g: "𝔊", j: "𝔍",
       k: "𝔎", l: "𝔏", m: "𝔐", n: "𝔑", o: "𝔒", p: "𝔓", q: "𝔔",
       s: "𝔖", t: "𝔗", u: "𝔘", v: "𝔙", w: "𝔚", x: "𝔛", y: "𝔜"]

  """

  @categories Enum.uniq(
                StringNaming.Defaults.categories() ++
                  Application.compile_env(:string_naming, :categories, [])
              )

  data_path = Path.join([__DIR__, "string_naming", "unicode", "NamesList.txt"])

  ~S"""
  0021	EXCLAMATION MARK
  	= factorial
  	= bang
  	x (inverted exclamation mark - 00A1)
  	x (latin letter retroflex click - 01C3)
  """

  extract_prop = fn
    _rest, [_category, _names, _props] = acc ->
      # TODO make properties available as well
      # IO.inspect rest, label: "★ property"
      acc
  end

  underscore = fn name ->
    name
    |> String.trim()
    |> String.replace(~r/\A(\d)/, "N_\\1")
    |> String.replace(~r/[^A-Za-z\d_ ]/, " ")
    |> String.split(" ")
    |> Enum.filter(&(&1 != ""))
    |> Enum.join("_")
    |> Macro.underscore()
  end

  @selected @categories
            |> Enum.filter(fn
              <<"#", _::binary>> -> false
              <<"=", _::binary>> -> false
              <<"+", _::binary>> -> false
              _ -> true
            end)
            |> Enum.map(&underscore.(&1))
  extract_name = fn
    _, <<"<"::binary, _::binary>>, [_category, _names, _props] = acc ->
      acc

    code, name, [category, names, props] ->
      [category, [{code, underscore.(name), category} | names], props]
  end

  [_category, names, _props] =
    Enum.reduce(File.stream!(data_path), ["Unknown", [], %{}], fn
      <<";"::binary, _::binary>>, acc ->
        acc

      <<"@\t"::binary, category::binary>>, [_, names, props] ->
        category = underscore.(category)
        category = if Enum.member?(@selected, category), do: category, else: ""
        [category, names, props]

      <<"@"::binary, _::binary>>, acc ->
        acc

      <<"\t"::binary, rest::binary>>, acc ->
        extract_prop.(rest, acc)

      code_name, [category, _, _] = acc when category != "" ->
        with [code, name] <- :binary.split(code_name, "\t") do
          extract_name.(code, name, acc)
        end

      <<"00", _::binary-size(2), "\t", _::binary>> = code_name, [_, names, props] ->
        with [code, name] <- :binary.split(code_name, "\t") do
          extract_name.(code, name, ["ascii", names, props])
        end

      _, acc ->
        acc
    end)

  names_tree =
    Enum.reduce(names, %{}, fn {code, name, category}, acc ->
      modules = [category | String.split(name, "_")] |> Enum.map(&Macro.camelize/1)

      {acc, ^modules} =
        Enum.reduce(modules, {acc, []}, fn
          key, {acc, keys} ->
            keys = :lists.reverse([key | :lists.reverse(keys)])

            {_, result} =
              get_and_update_in(acc, keys, fn
                nil -> {nil, %{}}
                map when is_map(map) -> {map, map}
                other -> {other, %{}}
              end)

            {result, keys}
        end)

      put_in(acc, modules, code)
    end)

  StringNaming.H.nesteds(["StringNaming"], names_tree)

  @doc ~S"""
  Returns graphemes for modules that have names matching the regular expression given as a parameter.
  The response is a plain keyword list with names taken from concatenated nested module names.

  ## Examples

      iex> StringNaming.graphemes ~r/AnimalFace/
      [
        animalfaces_bear_face: "🐻",
        animalfaces_cat_face: "🐱",
        animalfaces_cow_face: "🐮",
        animalfaces_dog_face: "🐶",
        animalfaces_dragon_face: "🐲",
        animalfaces_frog_face: "🐸",
        animalfaces_hamster_face: "🐹",
        animalfaces_horse_face: "🐴",
        animalfaces_monkey_face: "🐵",
        animalfaces_mouse_face: "🐭",
        animalfaces_panda_face: "🐼",
        animalfaces_pig_face: "🐷",
        animalfaces_pig_nose: "🐽",
        animalfaces_rabbit_face: "🐰",
        animalfaces_spouting_whale: "🐳",
        animalfaces_tiger_face: "🐯",
        animalfaces_wolf_face: "🐺"
      ]

      iex> StringNaming.graphemes ~r/fraktur.small/i
      [
        fraktursymbols_mathematical_fraktur_small_a: "𝔞",
        fraktursymbols_mathematical_fraktur_small_b: "𝔟",
        fraktursymbols_mathematical_fraktur_small_c: "𝔠",
        fraktursymbols_mathematical_fraktur_small_d: "𝔡",
        fraktursymbols_mathematical_fraktur_small_e: "𝔢",
        fraktursymbols_mathematical_fraktur_small_f: "𝔣",
        fraktursymbols_mathematical_fraktur_small_g: "𝔤",
        fraktursymbols_mathematical_fraktur_small_h: "𝔥",
        fraktursymbols_mathematical_fraktur_small_i: "𝔦",
        fraktursymbols_mathematical_fraktur_small_j: "𝔧",
        fraktursymbols_mathematical_fraktur_small_k: "𝔨",
        fraktursymbols_mathematical_fraktur_small_l: "𝔩",
        fraktursymbols_mathematical_fraktur_small_m: "𝔪",
        fraktursymbols_mathematical_fraktur_small_n: "𝔫",
        fraktursymbols_mathematical_fraktur_small_o: "𝔬",
        fraktursymbols_mathematical_fraktur_small_p: "𝔭",
        fraktursymbols_mathematical_fraktur_small_q: "𝔮",
        fraktursymbols_mathematical_fraktur_small_r: "𝔯",
        fraktursymbols_mathematical_fraktur_small_s: "𝔰",
        fraktursymbols_mathematical_fraktur_small_t: "𝔱",
        fraktursymbols_mathematical_fraktur_small_u: "𝔲",
        fraktursymbols_mathematical_fraktur_small_v: "𝔳",
        fraktursymbols_mathematical_fraktur_small_w: "𝔴",
        fraktursymbols_mathematical_fraktur_small_x: "𝔵",
        fraktursymbols_mathematical_fraktur_small_y: "𝔶",
        fraktursymbols_mathematical_fraktur_small_z: "𝔷"
      ]

      iex> StringNaming.graphemes ~r/\Aspace/i, false
      [
        space_medium_mathematical_space: " ",
        space_narrow_no_break_space: " ",
        space_ogham_space_mark: " ",
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


  """
  def graphemes(%Regex{} = filter, modules_only? \\ true) do
    with {:ok, modules} <- :application.get_key(:string_naming, :modules) do
      modules
      |> Enum.filter(fn m ->
        case {modules_only?, to_string(m)} do
          {false, _} ->
            match?({:module, ^m}, Code.ensure_loaded(m)) and function_exported?(m, :__all__, 0)

          {_, <<"Elixir.StringNaming."::binary, name::binary>>} ->
            Regex.match?(filter, name)

          _ ->
            false
        end
      end)
      |> Enum.flat_map(fn m ->
        m
        |> apply(:__all__, [])
        |> Enum.reduce([], fn {k, v}, acc ->
          <<"Elixir.StringNaming."::binary, name::binary>> = to_string(m)

          name =
            name
            |> String.split(~r/\W/)
            |> Kernel.++([k])
            |> Enum.join("_")

          if Regex.match?(filter, name),
            do: [{name |> String.downcase() |> String.to_atom(), v} | acc],
            else: acc
        end)
        |> Enum.reverse()
      end)
    end
  end
end

:code.purge(StringNaming.H)
:code.delete(StringNaming.H)
