defmodule Nodeponics.Mixfile do
  use Mix.Project

  @target "rpi2"

  def project do
    [app: :nodeponics,
     version: "0.0.1",
     elixir: "~> 1.2",
     archives: [nerves_bootstrap: "~> 0.1"],
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     target: @target,
     deps_path: "deps/#{@target}",
     build_path: "_build/#{@target}",
     config_path: "config/#{@target}/config.exs",
     aliases: aliases,
     deps: deps ++ system(@target)]
  end

  def application do
    [
        applications: [:logger, :cowboy, :httpoison, :timex, :sweet_xml, :xmerl, :nerves, :movi, :poison, :nerves_interim_wifi, :ex_aws],
        mod: {Nodeponics, []}
    ]
  end

  defp deps do
    [
        {:nerves, "~> 0.3.0"},
        {:timex, "~> 2.1"},
        {:poison, "~> 2.1"},
        {:cowboy, "~> 1.0"},
        {:sweet_xml, "~> 0.6.1"},
        {:httpoison, "~> 0.8.3"},
        {:movi, github: "NationalAssociationOfRealtors/movi"},
        {:nerves_interim_wifi, github: "nerves-project/nerves_interim_wifi", branch: "master"},
        {:ex_aws, "~> 0.5"},
    ]
  end

  def system("rpi2") do
    [{:nerves_system_rpi2, "~> 0.5.2"}]
  end

  def aliases do
    ["deps.precompile": ["nerves.precompile", "deps.precompile"],
     "deps.loadpaths":  ["deps.loadpaths", "nerves.loadpaths"]]
  end

end
