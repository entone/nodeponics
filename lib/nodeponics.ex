defmodule Nodeponics do
    use Application
    require Logger

    @name __MODULE__
    @interface "wlan0"
    @ssid "CRT-Internal"#System.get_env("SSID")
    @psk "CRTUnderscoreSpelledOut"#System.get_env("PSK")
    @key_management :"WPA-PSK"

    def start(_type, _args) do
        Nodeponics.Supervisor.start_link()
        Movi.add_handler(Nodeponics.Voice.Handler)
        Nerves.InterimWiFi.setup(@interface, ssid: @ssid, key_mgmt: @key_management, psk: @psk)
    end
end
