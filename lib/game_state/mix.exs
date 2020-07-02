defmodule ChessApp.MixProject do
  use Mix.Project

  def project do
    if Mix.env == :test, do: Application.ensure_all_started(:ex_unit)

    [
      app: :chess_app,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env),
      test_pattern: "*_test.ex",
      warn_test_pattern: "*_test.exs",
      dialyzer: [plt_add_apps: [:ex_unit]],
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {ChessApp, []},
      extra_applications: [:logger],
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:binbo, "~> 1.2"},
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.4", only: [:dev, :test], runtime: false},
    ]
  end

  # used for running dialyzer on tests
  defp elixirc_paths(:test), do: ["lib", "test"]
  defp elixirc_paths(_), do: ["lib"]
end
