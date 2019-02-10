defmodule Checksum.MixProject do
  use Mix.Project

  def project do
    [
      app: :checksum,
      version: "0.1.0",
      elixir: "~> 1.5",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      mod: {Checksum.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:phoenix, "~> 1.4.0"},
      {:jason, "~> 1.0"},
      {:plug_cowboy, "~> 2.0"},
      {:vex, "~> 0.8.0"},
      {:meck, "~> 0.8.13"},
      {:distillery, "~> 2.0"},
      {:versionary, "~> 0.3.0"}
    ]
  end
end
