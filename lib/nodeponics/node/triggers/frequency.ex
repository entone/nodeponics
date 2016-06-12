defmodule Nodeponics.Node.Trigger.Frequency do

    defmacro __using__(frequency: frequency, runtime: runtime, on_callback: on_callback, off_callback: off_callback, thing: thing) do
        quote bind_quoted: [frequency: frequency, runtime: runtime, on_callback: on_callback, off_callback: off_callback, thing: thing] do
            use Timex
            require Logger
            alias Nodeponics.Node
            alias Nodeponics.Event

            @behaviour GenEvent
            @frequency frequency
            @runtime runtime
            @on_callback on_callback
            @off_callback off_callback
            @thing thing
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
                        Logger.info "Turning #{@thing} on"
                        Node.send_message(state.parent, @thing, @on)
                        %State{state | :status => :waiting, :desired => @on, started: DateTime.universal}
                    :on when run_time >= @runtime ->
                        Logger.info "Turning #{@thing} off"
                        Node.send_message(state.parent, @thing, @off)
                        %State{state | :status => :waiting, :desired => @off}
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
                {:ok, %State{state | :status => :on, :started => DateTime.universal}}
            end

            def handle_event(_event = %Event{:type => @off_callback}, state) do
                Logger.info "#{@thing} OFF"
                {:ok, %State{state | :status => :off, :last => DateTime.universal}}
            end

            def handle_event(event = %Event{}, state) do
                {:ok, state}
            end
        end
    end
end
