to_binary = fn
  "" ->
    nil
  codepoints ->
    codepoints
    |> :binary.split(" ", [:global])
    |> Enum.map(&<<String.to_integer(&1, 16)::utf8>>)
    |> IO.iodata_to_binary
end

defmodule String.Naming.H do
  def nested_module(mod, v) do
    defmodule Module.concat(mod) do
      case v do
        %{code: code} ->
          @code code
          def sym, do: <<String.to_integer(@code, 16)::utf8>>
        _ -> String.Naming.H.nesteds(mod, v)
      end
    end
  end

  def nesteds(nested \\ [], map_or_code)
  def nesteds(nested, %{} = map) do
    Enum.each(map, fn
      {:code, value} ->
        String.Naming.H.nested_method(value)
      {k, v} ->
        mod = :lists.reverse([k | :lists.reverse(nested)])
        IO.inspect mod, label: "★ module"
        String.Naming.H.nested_module(mod, v)
    end)
  end
end

defmodule String.Naming do
  @moduledoc false

  ~S"""
  ; blah
  @@@ blah
  0021	EXCLAMATION MARK
  	= factorial
  	= bang
  	x (inverted exclamation mark - 00A1)
  	x (latin letter retroflex click - 01C3)
  	x (double exclamation mark - 203C)
  	x (interrobang - 203D)
  	x (heavy exclamation mark ornament - 2762)
  """

  data_path = Path.join([__DIR__, "string_naming", "unicode", "NamesList.txt"])

  extract_prop = fn
    rest, [_names, _codes] = acc ->
      IO.inspect rest, label: "★ property"
      acc
  end
  extract_name = fn
    _, <<"<" :: binary, _ :: binary>>, [_names, _codes] = acc -> acc
    code, name, [names, codes] ->
      fun_name = name
                 |> String.trim()
                 |> String.split([" ", "-"])
                 |> Enum.map(&Macro.underscore/1)
                 |> Enum.join("_")
                 |> String.to_atom()
      [[{code, fun_name} | names], codes]
  end

  [names, _props] = Enum.reduce File.stream!(data_path), [[], %{}], fn
    <<";" :: binary, _ :: binary>>, acc -> acc
    <<"@" :: binary, _ :: binary>>, acc -> acc
    <<"\t" :: binary, rest :: binary>>, acc -> extract_prop.(rest, acc)
    code_name, acc ->
      with [code, name] <- :binary.split(code_name, "\t") do
        extract_name.(code, name, acc)
      end
  end

  # "★ A71F :: modifier_letter_low_inverted_exclamation_mark"
  names_tree = Enum.reduce(Enum.take(names, 5000), %{}, fn {code, name}, acc ->
    modules = name
              |> Atom.to_string()
              |> String.split("_")
              |> Enum.map(&Macro.camelize/1)

    {acc, ^modules} = Enum.reduce(modules, {acc, []}, fn
      key, {acc, keys} ->
        keys = :lists.reverse([key | :lists.reverse(keys)])
        {_, result} = get_and_update_in(acc, keys, fn
          nil -> {nil, %{}}
          map when is_map(map) -> {map, map}
        end)
        {result, keys}
    end)
    put_in(acc, modules, %{code: code})
  end)

  String.Naming.H.nesteds(["String", "Naming"], names_tree)


  #for {code, name} <- names do
  #  IO.inspect "★ #{code} :: #{name}"
  #  def unquote(name)() do
  #    <<String.to_integer(unquote(code), 16)::utf8>>
  #  end
  #end

end
