defmodule Nodeponics do
    use Application
    require Logger
    alias :mnesia, as: Mnesia

    @name __MODULE__

    def start(_type, _args) do
        Nodeponics.Supervisor.start_link
    end

end
