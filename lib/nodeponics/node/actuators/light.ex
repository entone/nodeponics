defmodule Nodeponics.Node.Actuator.Light do
    use GenEvent
    use Timex

    require Logger

    alias Nodeponics.Node
    alias Nodeponics.Node.Event
    alias Nodeponics.UDPServer

    @start_hour 1
    @end_hour 18
    @lighton "lighton"
    @lightoff "lightoff"

    defmodule State do
        defstruct status: :off, start_time: nil, end_time: nil, parent: nil
    end

    def init(parent) do
        {:ok, %State{:parent => parent}}
    end

    def handle_event(event = %Event{:type => :clock}, state) do
        status = state.status
        new_state = case event.value do
            %DateTime{:hour => @start_hour} when status == :off or status == :waiting ->
                Logger.info "Turning light on"
                Node.send_message(state.parent, "light", "on")
                %State{state | :status => :waiting}
            %DateTime{:hour => @end_hour} when status == :on or status == :waiting ->
                Logger.info "Turning light off"
                Node.send_message(state.parent, "light", "off")
                %State{state | :status => :waiting}
            _ ->
                state
        end
        {:ok, new_state}
    end

    def handle_event(event = %Event{:type => :humidity}, state) do
        {:ok, state}
    end

    def handle_event(_event = %Event{:type => @lighton}, state) do
        Logger.info "Light ON"
        {:ok, %State{state | :status => :on}}
    end

    def handle_event(_event = %Event{:type => @lightoff}, state) do
        Logger.info "Light OFF"
        {:ok, %State{state | :status => :off}}
    end

    def handle_event(event = %Event{}, state) do
        {:ok, state}
    end
end
