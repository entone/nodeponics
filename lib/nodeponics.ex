defmodule Nodeponics do
    use Application
    require Logger
    alias :mnesia, as: Mnesia

    @name __MODULE__
    @interface "wlan0"
    @ssid "CRT-Internal"#System.get_env("SSID")
    @psk "CRTUnderscoreSpelledOut"#System.get_env("PSK")
    @key_management :"WPA-PSK"

    def start(_type, _args) do
        #Mnesia.create_schema([node])
        #Mnesia.start()
        {:ok, pid} = Nodeponics.Supervisor.start_link()
        Movi.add_handler(Nodeponics.Voice.Handler)
        Nerves.InterimWiFi.setup(@interface, ssid: @ssid, key_mgmt: @key_management, psk: @psk)
        {:ok, pid}
    end
end
