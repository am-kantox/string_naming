defmodule StringNaming.Mixfile do
  use Mix.Project

  @application :string_naming

  def project do
    [
      app: @application,
      version: "0.2.0",
      elixir: "~> 1.4",
      start_permanent: Mix.env == :prod,
      description: description(),
      package: package(),
      deps: deps()
    ]
  end

  def application, do: []

  defp deps, do: [ {:ex_doc, ">= 0.0.0", only: :dev} ]

  defp description do
    """
    Compile-time generated set of modules to ease an access to a predefined subset of UTF8 symbols.
    """
  end

  defp package do
    [
     name: @application,
     files: ~w|lib mix.exs README.md|,
     maintainers: ["Aleksei Matiushkin"],
     licenses: ["MIT"],
     links: %{"GitHub" => "https://github.com/am-kantox/#{@application}",
              "Docs" => "https://hexdocs.pm/#{@application}"}]
  end

end
