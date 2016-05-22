defmodule Nodeponics do
    use Application
    require Logger
    alias :mnesia, as: Mnesia

    @name __MODULE__

    def start(_type, _args) do
        Mnesia.create_schema([node])
        Mnesia.start()
        Nodeponics.Supervisor.start_link()
    end
end
