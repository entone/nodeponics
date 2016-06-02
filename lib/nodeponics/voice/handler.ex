defmodule Nodeponics.Voice.Handler do
    use GenEvent
    require Logger
    alias Movi.Event
    alias Nodeponics.Node

    def handle_event(event = %Event{:message => "LET THERE BE LIGHT"}, state) do
        Logger.info("Light ON!")
        IO.inspect event
        Node.light(:"1a0036000347343337373739", "on")
        {:ok, state}
    end

    def handle_event(event = %Event{:message => "GO DARK"}, state) do
        Logger.info("Light OFF!")
        IO.inspect event
        Node.light(:"1a0036000347343337373739", "off")
        {:ok, state}
    end

    def handle_event(event = %Event{}, state) do
        IO.inspect event
        {:ok, state}
    end

end
