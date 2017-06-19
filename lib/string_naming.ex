defmodule String.Naming.H do
  def nested_module(mod, children) do
    [funs, mods] = Enum.reduce(children, [%{}, %{}], fn
      {k, v}, [funs, mods] when is_binary(v) -> [Map.put(funs, k, v), mods]
      {k, v}, [funs, mods] -> [funs, Map.put(mods, k, v)]
    end)
    defmodule Module.concat(mod) do
      Enum.each(funs, fn {name, value} ->
        name = name |> Macro.underscore |> String.to_atom
        ast = quote do: def unquote(name)(), do: <<String.to_integer(unquote(value), 16)::utf8>>
        Code.eval_quoted(ast, [name: name, value: value], __ENV__)
      end)
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
      String.Naming.H.nesteds(mod, mods)
    end
  end

  def nesteds(nested \\ [], map_or_code)
  def nesteds(nested, %{} = map) do
    Enum.each(map, fn
      {_key, code} when is_binary(code) -> :ok
      {k, v} ->
        mod = :lists.reverse([k | :lists.reverse(nested)])
        String.Naming.H.nested_module(mod, v)
    end)
  end
end

defmodule String.Naming do
  @moduledoc false

  @categories Application.get_env(:string_naming, :categories)

  ~S"""
  0021	EXCLAMATION MARK
  	= factorial
  	= bang
  	x (inverted exclamation mark - 00A1)
  	x (latin letter retroflex click - 01C3)
  """

  data_path = Path.join([__DIR__, "string_naming", "unicode", "NamesList.txt"])

  extract_prop = fn
    _rest, [_category, _names, _props] = acc ->
      # IO.inspect rest, label: "★ property"
      acc
  end
  underscore = fn name ->
    name
    |> String.trim
    |> String.replace(~r/\A(\d)/, "N_\\1")
    |> String.replace(~r/[^A-Za-z\d_ ]/, " ")
    |> String.split(" ")
    |> Enum.filter(& &1 != "")
    |> Enum.join("_")
    |> Macro.underscore()
  end
  @selected @categories
            |> Enum.filter(fn
                  <<"#" :: binary, _ :: binary>> -> false
                  <<"=" :: binary, _ :: binary>> -> false
                  _ -> true
               end)
            |> Enum.map(& underscore.(&1))
  extract_name = fn
    _, <<"<" :: binary, _ :: binary>>, [_category, _names, _props] = acc -> acc
    code, name, [category, names, props] ->
      [category, [{code, underscore.(name), category} | names], props]
  end

  [_category, names, _props] = Enum.reduce File.stream!(data_path), ["Unknown", [], %{}], fn
    <<";" :: binary, _ :: binary>>, acc -> acc
    <<"@\t" :: binary, category :: binary>>, [_, names, props] ->
      category = underscore.(category)
      category = if Enum.member?(@selected, category), do: category, else: ""
      [category, names, props]
    <<"@" :: binary, _ :: binary>>, acc -> acc
    <<"\t" :: binary, rest :: binary>>, acc -> extract_prop.(rest, acc)
    code_name, [category, _, _] = acc ->
      if "" == category do
        acc
      else
        with [code, name] <- :binary.split(code_name, "\t") do
          extract_name.(code, name, acc)
        end
      end
  end

  names_tree = Enum.reduce(names, %{}, fn {code, name, category}, acc ->
    modules = [category | String.split(name, "_")] |> Enum.map(&Macro.camelize/1)
    {acc, ^modules} = Enum.reduce(modules, {acc, []}, fn
      key, {acc, keys} ->
        keys = :lists.reverse([key | :lists.reverse(keys)])
        {_, result} = get_and_update_in(acc, keys, fn
          nil -> {nil, %{}}
          map when is_map(map) -> {map, map}
          other -> {other, %{}}
        end)
        {result, keys}
    end)
    put_in(acc, modules, code)
  end)

  String.Naming.H.nesteds(["String", "Naming"], names_tree)


  #for {code, name} <- names do
  #  IO.inspect "★ #{code} :: #{name}"
  #  def unquote(name)() do
  #    <<String.to_integer(unquote(code), 16)::utf8>>
  #  end
  #end

end

:code.delete String.Naming.H
:code.purge String.Naming.H
