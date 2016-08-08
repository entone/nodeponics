# Nodeponics

Nodeponics is an automation system for aquaponic systems. It runs on small embedded computers such as a [RaspberryPi](https://www.raspberrypi.org/). At it's core Nodeponics is a UDP server and client that communicates with a [Particle.io Photon](https://www.particle.io/products/hardware/photon-wifi-dev-kit) based control system, [SensorNode](https://github.com/entone/SensorNode)

Nodeponics monitors and controls several water quality measurements, such as temperature, Dissolved Oxygen and PH.

Along with logging data to local DETS tables, it also saves timelapse images to Amazon S3 for later viewing.

It provides a simple web frontend for monitoring which provides Websocket and MJPEG interfaces for data display and control.

Nodeponics is built using [Elixir](http://elixir-lang.org/) and [Nerves](http://nerves-project.org/)
