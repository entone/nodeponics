defmodule Nodeponics.Node.Actuator.Pump do
    use GenEvent
    use Timex
    require Logger
    alias Nodeponics.Node.Event
    alias Nodeponics.Node

    @frequency 900 #15 minutes
    @runtime 180 # 3 minutes
    @pumpon "pumpon"
    @pumpoff "pumpoff"
    @on "on"
    @off "off"

    defmodule State do
        defstruct status: :off, desired: nil, last: nil, parent: nil, started: nil
    end

    def init(parent) do
        {:ok, %State{:parent => parent, :last => DateTime.universal, :started => DateTime.universal}}
    end

    def handle_event(event = %Event{:type => :clock}, state) do
        now = event.value
        freq = DateTime.diff(now, state.last, :seconds)
        run_time = DateTime.diff(now, state.started, :seconds)
        new_state = case state.status do
            :off when freq >= @frequency ->
                Logger.info "Turning pump on"
                Node.send_message(state.parent, "pump", @on)
                %State{state | :status => :waiting, :desired => @on, started: DateTime.universal}
            :on when run_time >= @runtime ->
                Logger.info "Turning pump off"
                Node.send_message(state.parent, "pump", @off)
                %State{state | :status => :waiting, :desired => @off}
            :waiting ->
                Logger.info "Turning pump #{state.desired}"
                Node.send_message(state.parent, "pump", state.desired)
                state
            set ->
                state
        end
        {:ok, new_state}
    end

    def handle_event(_event = %Event{:type => @pumpon}, state) do
        Logger.info "Pump ON"
        {:ok, %State{state | :status => :on, :started => DateTime.universal}}
    end

    def handle_event(_event = %Event{:type => @pumpoff}, state) do
        Logger.info "Pump OFF"
        {:ok, %State{state | :status => :off, :last => DateTime.universal}}
    end

    def handle_event(event = %Event{}, state) do
        {:ok, state}
    end
end
