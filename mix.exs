defmodule Nodeponics.Mixfile do
    use Mix.Project

    def project do
    [
        app: :nodeponics,
        version: "0.0.1",
        elixir: "~> 1.2",
        build_embedded: Mix.env == :prod,
        start_permanent: Mix.env == :prod,
        deps: deps
        ]
    end

    def application do
    [
        applications: [:logger, :cowboy, :httpoison, :sweet_xml, :xmerl, :timex, :poison, :ex_aws],
        mod: {Nodeponics, []}
    ]
    end

    defp deps do
    [
        {:timex, "~> 2.1"},
        {:poison, "~> 2.1"},
        {:cowboy, "~> 1.0"},
        {:sweet_xml, "~> 0.6.1"},
        {:httpoison, "~> 0.8.3"},
        {:ex_aws, "~> 0.5"},
    ]
    end
end
