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
    [{:ecto_psql_extras, "~> 0.7 or ~> 0.8"}]
  end
end
