defmodule ElixirRss.MixProject do
  use Mix.Project

  def project do
    [
      app: :elixir_rss,
      version: "0.1.0",
      elixir: "~> 1.14",
      description: "RSS Feed parser built with Elixir",
      start_permanent: Mix.env() == :prod,
      build_embedded: Mix.env() == :prod,
      package: package(),
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp package do
    [
      maintainers: ["virkillz"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/virkillz/elixir_rss"}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:html_sanitize_ex, "~> 1.4"},
      {:httpoison, "~> 1.8"},
      {:sweet_xml, "~> 0.7.1"},
      {:timex, "~> 3.7"},
      {:ex_doc, "~> 0.27", only: :dev, runtime: false}
    ]
  end
end
