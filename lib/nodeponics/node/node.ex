defmodule Nodeponics.Node do
    use GenServer
    require Logger

    alias Nodeponics.UDPServer
    alias Nodeponics.Node.Sensor
    alias Nodeponics.Node.Actuator
    alias Nodeponics.Node.Clock
    alias Nodeponics.Message
    alias Nodeponics.Event
    alias :mnesia, as: Mnesia

    @stats "stats"
    @light "light"
    @update_camera "update_camera"

    @sensor_keys [:do, :humidity, :ph, :temperature, :water_temperature]
    @actuator_keys [:fan, :light, :pump]

    defmodule Sensors do
        defstruct [:do, :humidity, :ph, :temperature, :water_temperature]
    end

    defmodule Actuators do
        defstruct [fan: Actuator.Fan, light: Actuator.Light, pump: Actuator.Pump]
    end

    defmodule State do
        defstruct [:id, :last_stats, :ip, :events, :camera, :image, sensors: %Sensors{}, actuators: %Actuators{}]
    end

    def start_link(message) do
        GenServer.start_link(__MODULE__, message, name: message.id)
    end

    def send_message(node, type, data) do
        GenServer.cast(node, {:send, type, data})
    end

    def add_event_handler(node, handler, parent) do
        GenServer.call(node, {:add_handler, handler, parent})
    end

    def remove_event_handler(node, handler) do
        GenServer.call(node, {:remove_handler, handler})
    end

    def id(node) do
        GenServer.call(node, :id)
    end

    def ack do
        GenServer.cast(self, :ack)
    end

    def light(node, command) do
        send_message(node, "light", command)
    end

    def init(message) do
        webcams = ['http://192.168.1.97/image/jpeg.cgi',]
        url = Enum.random(webcams)
        Logger.info("Starting node: #{message.id}")
        #Mnesia.create_table(:node, [attributes: [:id, :camera]])
        #Mnesia.dirty_write({:node, message.id, url})
        {:ok, events} = GenEvent.start_link([])
        {:ok, _clock} = Clock.start_link(events)
        {:ok, camera} = Sensor.Camera.start_link(url, events)
        actuators = add_event_handlers(events)
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
            :actuators => actuators,
            :camera => camera,
        }}
    end

    def add_event_handlers(events) do
        Enum.reduce(@actuator_keys, %Actuators{}, fn(x, acc) ->
            Map.put(acc, x, GenEvent.add_mon_handler(events, Map.get(acc, x), self()))
        end)
    end

    def update_state(node, message) do
        GenServer.call(node, {:update_state, message})
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
        ack
        {:noreply, new_state}
    end

    def handle_info(message = %Message{:type => @light}, state) do
        GenServer.cast(message.id, {:send, @light, message.data})
        {:noreply, state}
    end

    def handle_info(message = %Message{:type => @update_camera}, state) do
        update_camera = fn ->
            Mnesia.write({:node, message.id, message.data})
        end
        Mnesia.transaction(update_camera) |> IO.inspect
        Mnesia.dirty_read({:node, message.id})
        {:noreply, state}
    end

    def handle_info(message = %Message{}, state) do
        GenEvent.notify(state.events, %Event{:type => message.type, :value => message.data, :id => message.id})
        {:noreply, state}
    end

    def handle_info({:gen_event_EXIT, _handler, _reason}, state) do
        add_event_handlers(state.events)
        {:noreply, state}
    end

    def handle_call({:update_state, message}, _from, state) do
        {:reply, :ok, %State{state | :ip => message.ip}}
    end

    def handle_call({:add_handler, handler, parent}, _from, state) do
        {:reply, GenEvent.add_mon_handler(state.events, handler, parent), state}
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

    def handle_call(:id, _from, state) do
        {:reply, state.id, state}
    end

    def handle_cast(:ack, state) do
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

    def handle_cast({:send, type, data}, state) do
        message = %Message{
            :type => type,
            :data => data,
            :ip => state.ip,
            :id => state.id
        }
        UDPServer.send_message(message)
        GenEvent.notify(state.events, %Event{:type => :node_message, :value => %Message{message | :ip => nil}})
        {:noreply, state}
    end

    def format_status(:normal, [pdict, state]) do
        sensors = Enum.reduce(@sensor_keys, %Sensors{}, fn(x, acc) ->
            Map.put(acc, x, Sensor.Analog.state(Map.get(state.sensors, x)))
        end)
        actuators = Enum.reduce(GenEvent.which_handlers(state.events), %{}, fn(x, acc) ->
            x
        end)
        %{:sensors => sensors, :id => state.id}
    end
end
