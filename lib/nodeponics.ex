defmodule Nodeponics do
    use Application
    require Logger
    alias :mnesia, as: Mnesia

    @name __MODULE__
    @interface "wlan0"
    @ssid "CRT-Internal"#System.get_env("SSID")
    @psk "CRTUnderscoreSpelledOut"#System.get_env("PSK")
    @key_management :"WPA-PSK"

    defmodule Event do
        defstruct [:type, :value, :id]
    end

    defmodule Message do
        defstruct [:id, :type, :data, :ip, :port]
    end

    def start(_type, _args) do
        {:ok, pid} = Nodeponics.Supervisor.start_link
        Movi.add_handler(Nodeponics.Voice.Handler)
        Nerves.InterimWiFi.setup(@interface, ssid: @ssid, key_mgmt: @key_management, psk: @psk)
        IO.inspect start_writable_fs()
        train_voice_recognition
        {:ok, pid}
    end

    def train_voice_recognition do
        :timer.sleep(100)
        Movi.callsign(Application.get_env(:movi, :callsign))
        :timer.sleep(100)
        train_list(Application.get_env(:movi, :verbs))
        train_list(Application.get_env(:movi, :combinators))
        train_list(Application.get_env(:movi, :descriptors))
        train_list(Application.get_env(:movi, :locations))
        train_list(Application.get_env(:movi, :things))
        train_list(Application.get_env(:movi, :numbers))
        Movi.trainsentences
    end

    defp train_list(list) do
        Enum.each(list, fn(sentence) ->
            Movi.addsentence(sentence)
            :timer.sleep(100)
        end)
    end

    defp format_appdata() do
        case System.cmd("mke2fs", ["-t", "ext4", "-L", "APPDATA", "/dev/mmcblk0p3"]) do
            {_, 0} -> :ok
            _ -> :error
        end
    end

    defp maybe_mount_appdata() do
        if !File.exists?("/mnt/.initialized") do
            mount_appdata()
        else
            :ok
        end
    end

    defp mount_appdata() do
        case System.cmd("mount", ["-t", "ext4", "/dev/mmcblk0p3", "/mnt"]) do
            {_, 0} ->
                File.write("/mnt/.initialized", "mounted")
                :ok
            _ ->
                :error
        end
    end

    defp start_writable_fs() do
        case maybe_mount_appdata() do
            :ok -> :ok
            :error ->
                case format_appdata() do
                    :ok ->
                        mount_appdata()
                        :ok
                    :error -> :error
                end
        end
    end
end
