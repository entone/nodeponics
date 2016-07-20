defmodule Nodeponics.Mixfile do
  use Mix.Project

  @target System.get_env("NERVES_TARGET") || "rpi2"

  def project do
    [app: :nodeponics,
     version: "0.0.1",
     target: @target,
     archives: [nerves_bootstrap: "~> 0.1.2"],
     deps_path: "deps/#{@target}",
     build_path: "_build/#{@target}",
     config_path: "config/#{@target}/config.exs",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     aliases: aliases,
     deps: deps ++ system(@target)]
  end

  def application do
    [
        applications: [:logger, :cowboy, :httpoison, :timex, :sweet_xml, :xmerl, :nerves, :movi, :poison, :nerves_interim_wifi, :ex_aws, :nerves_firmware_http],
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
        {:nerves_firmware_http, github: "NationalAssociationOfRealtors/nerves_firmware_http", branch: "master"},
        {:erlware_commons, "~> 0.21.0", override: true},
        {:ex_aws, "~> 0.5"},
    ]
  end

  def system(target) do
    [{:"nerves_system_#{target}", ">= 0.6.0"}]
  end

  def aliases do
    ["deps.precompile": ["nerves.precompile", "deps.precompile"],
     "deps.loadpaths":  ["deps.loadpaths", "nerves.loadpaths"]]
  end

end
