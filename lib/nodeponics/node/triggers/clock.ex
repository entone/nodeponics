defmodule Nodeponics.Node.Trigger.Clock do

    defmacro __using__(start_hour: start_hour, end_hour: end_hour, on_callback: on_callback, off_callback: off_callback, thing: thing) do
        quote bind_quoted: [start_hour: start_hour, end_hour: end_hour, on_callback: on_callback, off_callback: off_callback, thing: thing] do
            use Timex
            require Logger
            alias Nodeponics.Node
            alias Nodeponics.Event

            @behaviour GenEvent
            @start_hour start_hour
            @end_hour end_hour
            @on_callback on_callback
            @off_callback off_callback
            @thing thing

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
                        Logger.info "Turning #{@thing} on"
                        Node.send_message(state.parent, @thing, "on")
                        %State{state | :status => :waiting, :desired => "on"}
                    :on when hour >= @end_hour or hour < @start_hour ->
                        Logger.info "Turning #{@thing} off"
                        Node.send_message(state.parent, @thing, "off")
                        %State{state | :status => :waiting, :desired => "off"}
                    :waiting ->
                        Logger.info "Turning #{@thing} #{state.desired}"
                        Node.send_message(state.parent, @thing, state.desired)
                        state
                    set ->
                        state
                end
                {:ok, new_state}
            end

            def handle_event(_event = %Event{:type => @on_callback}, state) do
                Logger.info "#{@thing} ON"
                {:ok, %State{state | :status => :on}}
            end

            def handle_event(_event = %Event{:type => @off_callback}, state) do
                Logger.info "#{@thing} OFF"
                {:ok, %State{state | :status => :off}}
            end

            def handle_event(event = %Event{}, state) do
                {:ok, state}
            end
        end
    end

end
