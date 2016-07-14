defmodule Nodeponics.Node.Sensor.Analog do
    alias Nodeponics.Event
    require Logger

    defmodule State do
        defstruct min: 99999999, max: 0, mean: 0, current: 0, total: 0, events: nil, sensor_type: nil, id: nil
    end

    def start_link(events, type) do
        {:ok, agent} = Agent.start_link(fn -> %State{events: events, sensor_type: type} end)
        agent
    end

    def mean(agent) do
        Agent.get(agent, fn(state) -> state.mean end)
    end

    def min(agent) do
        Agent.get(agent, fn(state) -> state.min end)
    end

    def max(agent) do
        Agent.get(agent, fn(state) -> state.max end)
    end

    def current(agent) do
        Agent.get(agent, fn(state) -> state.current end)
    end

    def state(agent) do
        Agent.get(agent, fn(state) ->
            %State{state | :events => nil}
        end)
    end

    def update(agent, value) do
        Agent.update(agent, fn(state) ->
            GenEvent.notify(state.events, %Event{type: state.sensor_type, value: value})
            total = state.mean + value
            mean = total / 2
            %State{state |
                :current => value,
                :min => min(state.min, value),
                :max => max(state.max, value),
                :mean => mean,
                :total => state.total + 1,
            }
        end)
    end

end
