defmodule Repro.MixProject do
  use Mix.Project

  def project do
    [
      app: :repro,
      version: "0.1.0",
      elixir: "~> 1.16",
      deps: deps()
    ]
  end

  defp deps do
    [{:excoveralls, "~> 0.17", only: :test, runtime: false}]
  end
end
