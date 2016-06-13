defmodule Nodeponics.Node.Actuator.Light do
    use GenEvent
    use Timex

    require Logger

    alias Nodeponics.Node
    alias Nodeponics.Node.Event
    alias Nodeponics.UDPServer

    @start_hour 11
    @end_hour 23
    @lighton "lighton"
    @lightoff "lightoff"

    defmodule State do
        defstruct status: :off, desired: nil, start_time: nil, end_time: nil, parent: nil
    end

    def init(parent) do
        {:ok, %State{:parent => parent}}
    end

    def handle_event(event = %Event{:type => :clock}, state) do
        hour = event.value.hour
        new_state = case state.status do
            :off when hour >= @start_hour and hour < @end_hour ->
                Logger.info "Turning light on"
                Node.send_message(state.parent, "light", "on")
                %State{state | :status => :waiting, :desired => "on"}
            :on when hour >= @end_hour or hour < @start_hour ->
                Logger.info "Turning light off"
                Node.send_message(state.parent, "light", "off")
                %State{state | :status => :waiting, :desired => "off"}
            :waiting
                Logger.info "Turning light #{state.desired}"
                Node.send_message(state.parent, "light", state.desired)
                state
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
