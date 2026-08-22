defmodule RenovateHexWidenRepro.MixProject do
  use Mix.Project

  def project do
    [
      app: :renovate_hex_widen_repro,
      version: "0.1.0",
      elixir: "~> 1.16",
      deps: deps()
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      # BUG - two-part "~>" with major 0.
      # hex reads "~> 0.17" as ">= 0.17.0 and < 1.0.0", thus 0.18.5 is already
      # permitted and no change is necessary. Renovate widens to
      # "~> 0.17 or ~> 0.18".
      {:excoveralls, "~> 0.17", only: :test, runtime: false},

      # BUG - the same defect, second example.
      # hex reads "~> 0.6" as ">= 0.6.0 and < 1.0.0", thus 0.7.3 is permitted.
      {:req, "~> 0.6 or ~> 0.7"},

      # CONTROL - three-part "~>" with major 0.
      # hex reads "~> 0.13.0" as ">= 0.13.0 and < 0.14.0", thus 0.15.0 is not
      # permitted. Here a widen to "~> 0.13.0 or ~> 0.15.0" is correct.
      {:sobelow, "~> 0.13.0", only: :dev, runtime: false},

      # CONTROL - two-part "~>" with major 1.
      # hex reads "~> 1.6" as ">= 1.6.0 and < 2.0.0", thus 1.7.19 is permitted.
      # Renovate correctly proposes no change.
      {:credo, "~> 1.6", only: :dev, runtime: false}
    ]
  end
end
