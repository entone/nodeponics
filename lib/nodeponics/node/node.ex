defmodule Nodeponics.Node do
    use GenServer
    require Logger

    alias Nodeponics.UDPServer
    alias Nodeponics.Node.Sensor
    alias Nodeponics.Node.Actuator
    alias Nodeponics.Node.Clock
    alias Nodeponics.UDPServer.Message

    @stats "stats"
    @init "ack"
    @sensor_keys [:do, :ec, :humidity, :ph, :temperature]

    defmodule Event do
        defstruct [:type, :value]
    end

    defmodule Sensors do
        defstruct [:do, :ec, :humidity, :ph, :temperature]
    end

    defmodule State do
        defstruct [:id, :last_stats, :ip, :events, :camera, :image, sensors: %Sensors{}]
    end

    def start_link(message) do
        GenServer.start_link(__MODULE__, message, name: message.id)
    end

    def send_message(node, type, data) do
        GenServer.call(node, {:send, type, data})
    end

    def add_event_handler(node, handler, parent) do
        GenServer.call(node, {:add_handler, handler, parent})
    end

    def remove_event_handler(node, handler) do
        GenServer.call(node, {:remove_handler, handler})
    end

    def light(node, bool) do
        Nodeponics.Node.send_message(node, "light", bool)
    end

    def current_image(node) do
        GenServer.call(node, :current_image)
    end

    def state(node) do
        GenServer.call(node, :state)
    end

    def ack do
        Process.send_after(self, :ack, 100)
    end

    def init(message) do
        url = 'http://entropealabs.net/camera/front.jpg'
        Logger.info("Starting node: #{message.id}")
        {:ok, events} = GenEvent.start_link([])
        {:ok, _clock} = Clock.start_link(events)
        {:ok, camera} = Sensor.Camera.start_link(url, events)
        add_event_handlers(events)
        sensors = Enum.reduce(@sensor_keys, %Sensors{}, fn(x, acc) ->
            Map.put(acc, x, Sensor.Analog.start_link(events, x))
        end)
        ack
        {:ok, %State{
            :id => message.id,
            :last_stats => :erlang.system_time(:milli_seconds),
            :ip => message.ip,
            :events => events,
            :sensors => sensors,
            :camera => camera,
        }}
    end

    def add_event_handlers(events) do
        GenEvent.add_mon_handler(events, Actuator.Fan, self())
        GenEvent.add_mon_handler(events, Actuator.Light, self())
        GenEvent.add_mon_handler(events, Actuator.Pump, self())
    end

    def handle_info(message = %Message{:type => @stats}, state) do
        #Logger.info "Node Stats: #{state.id}"
        Enum.each(@sensor_keys, fn(x) ->
            Sensor.Analog.update(
                Map.get(state.sensors, x),
                Map.get(message.data, Atom.to_string(x), 0)
            )
        end)
        new_state = %State{state | :last_stats => :erlang.system_time(:milli_seconds)}
        {:noreply, new_state}
    end

    def handle_info(message = %Message{:type => @init}, state) do
        GenServer.call(self, {:send, "ack", true})
        {:noreply, state}
    end

    def handle_info(_message = %Message{}, state) do
        {:noreply, state}
    end

    def handle_info({:gen_event_EXIT, _handler, _reason}, state) do
        add_event_handlers(state.events)
        {:noreply, state}
    end

    def handle_info(:ack, state) do
        UDPServer.send_message(
            %Message{
                :type => "ack",
                :data => true,
                :ip => state.ip,
                :id => state.id
            }
        )
        {:noreply, state}
    end

    def handle_call({:add_handler, handler, parent}, _from, state) do
        {:reply, GenEvent.add_mon_handler(state.events, handler, parent), state}
    end

    def handle_call(:current_image, _from, state) do
        {:reply, Sensor.Camera.current_image(state.camera), state}
    end

    def handle_call(:state, _from, state) do
        IO.inspect GenEvent.which_handlers(state.events)
        {:reply, %{}, state}
    end

    def handle_call({:remove_handler, handler}, _from, state) do
        Logger.info "Removing Handler"
        IO.inspect handler
        {:reply, GenEvent.remove_handler(state.events, handler, []), state}
    end

    def handle_call({:send, type, data}, _from, state) do
        message = %Message{
            :type => type,
            :data => data,
            :ip => state.ip,
            :id => state.id
        }
        UDPServer.send_message message
        GenEvent.notify(state.events, %Event{:type => :node_message, :value => %Message{message | :ip => nil}})
        {:reply, %{}, state}
    end
end
