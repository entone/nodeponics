defmodule Nodeponics.Node.Actuator.Fan do
    use GenEvent
    alias Nodeponics.Node.Event

    def handle_event(_event = %Event{}, state) do
        {:ok, state}
    end
end
