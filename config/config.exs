# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

# This configuration is loaded before any dependency and is restricted
# to this project. If another project depends on this project, this
# file won't be loaded nor affect the parent project. For this reason,
# if you want to provide default values for your application for
# 3rd-party users, it should be done in your "mix.exs" file.

# You can configure for your application as:
#
config :nodeponics, udp_port: 5683, tcp_port: 8081, cipher_key: System.get_env("SKEY")
config :nodeponics, multicast_address: {239, 255, 41, 11}
config :nodeponics, sensor_keys: [:do, :humidity, :ph, :temperature, :water_temperature]
config :nodeponics, tty: "/dev/ttyAMA0"
config :movi, speed: 9600
config :movi, callsign: "ROSETTA"

config :nerves_interim_wifi,
  regulatory_domain: "US"

config :nerves, :firmware,
  fwup_conf: "config/rpi2/fwup.conf",
  rootfs_additions: "config/rpi2/rootfs-additions"

config :ex_aws,
    region: "us-west-2",
    access_key_id: System.get_env("AWS_ACCESS_KEY_ID"),
    secret_access_key: System.get_env("AWS_SECRET_ACCESS_KEY")
#
# And access this configuration in your application as:
#
#     Application.get_env(:nodeponics, :key)
#
# Or configure a 3rd-party app:
#
#     config :logger, level: :info
#

# It is also possible to import configuration files, relative to this
# directory. For example, you can emulate configuration per environment
# by uncommenting the line below and defining dev.exs, test.exs and such.
# Configuration from the imported file will override the ones defined
# here (which is why it is important to import them last).
#
import_config "words.exs"
