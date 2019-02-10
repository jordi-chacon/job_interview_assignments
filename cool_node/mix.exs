defmodule CoolNode.MixProject do
  use Mix.Project

  def project do
    [
      app: :cool_node,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      mod: {CoolNode.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  defp deps do
    [
      {:distillery, "~> 2.0"}
    ]
  end
end
