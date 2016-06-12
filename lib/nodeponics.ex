defmodule Nodeponics do
    use Application
    require Logger
    alias :mnesia, as: Mnesia

    @name __MODULE__

    defmodule Message do
        defstruct [:id, :type, :data, :ip, :port]
    end

    defmodule Event do
        defstruct [:type, :value, :id]
    end

    def start(_type, _args) do
        Nodeponics.Supervisor.start_link
    end

end
