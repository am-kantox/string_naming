defmodule StringNaming.Mixfile do
  use Mix.Project

  @app :string_naming
  @version "0.7.0"

  def project do
    [
      app: @app,
      version: @version,
      elixir: "~> 1.10",
      start_permanent: Mix.env == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      docs: docs()
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
     name: @app,
     files: ~w|config lib mix.exs README.md|,
     maintainers: ["Aleksei Matiushkin"],
     licenses: ["MIT"],
     links: %{"GitHub" => "https://github.com/am-kantox/#{@app}",
              "Docs" => "https://hexdocs.pm/#{@app}"}]
  end

  defp docs() do
    [
      main: "StringNaming",
      source_ref: "v#{@version}",
      canonical: "http://hexdocs.pm/#{@app}",
      # logo: "stuff/images/logo.png",
      source_url: "https://github.com/am-kantox/#{@app}"
      # extras: [ "stuff/pages/intro.md" ],
    ]
  end
end
