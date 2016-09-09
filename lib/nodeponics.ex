defmodule Nodeponics do
    use Application
    require Logger

    @name __MODULE__
    @interface "wlan0"
    @ssid System.get_env("SSID")
    @psk System.get_env("PSK")
    @key_management :"WPA-PSK"

    defmodule Event do
        defstruct [:type, :value, :id]
    end

    defmodule Message do
        defstruct [:id, :type, :data, :ip, :port]
    end

    def start(_type, _args) do
        {:ok, pid} = Nodeponics.Supervisor.start_link
        Logger.debug("SSID: #{@ssid}")
        Logger.debug("PSK: #{@psk}")
        Nerves.InterimWiFi.setup(@interface, ssid: @ssid, key_mgmt: @key_management, psk: @psk)
        {:ok, pid}
    end
end
