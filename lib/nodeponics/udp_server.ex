defmodule Nodeponics.UDPServer do
    use GenServer
    require Logger
    alias Nodeponics.DatagramSupervisor

    defmodule Message do
        defstruct [:id, :type, :data, :ip, :port]
    end

    defmodule State do
        defstruct [:ip, :udp]
    end

    @init "init"

    @port Application.get_env(:nodeponics, :port)
    @multicast Application.get_env(:nodeponics, :multicast_address)
    @interfaces ['wlan0', 'eth0']

    def start_link do
        GenServer.start(__MODULE__, @port, name: __MODULE__)
    end

    def send_message(message) do
        GenServer.call(__MODULE__, {:send, message})
    end

    def process(ip, port, data) do
        data |> parse(ip, port) |> IO.inspect |> handle
    end

    def parse(data, ip, port) do
        message = data |> Poison.decode!(as: %Message{})
        %Message{message | :ip => ip, :port => port, :id => String.to_atom(message.id)}
    end

    def handle(message = %Message{}) do
        case Process.whereis(message.id) do
            nil -> Nodeponics.NodeSupervisor.start_node(message)
            _ -> true
        end
        send(message.id, message)
    end

    def init(port) do
        intfs =
            :inet.getifaddrs()
            |> elem(1)
            |> Enum.find(fn(inf) ->
                Enum.member?(@interfaces, elem(inf, 0))
            end)
            |> elem(1)
        ip = intfs[:addr]
        Logger.info "Accepting datagrams on #{:inet_parse.ntoa(ip)}:#{port}"
        udp_options = [
            :binary,
            active:          10,
            add_membership:  { @multicast, {0,0,0,0} },
            multicast_if:    {0,0,0,0},
            multicast_loop:  false,
            multicast_ttl:   4,
            reuseaddr:       true
        ]
        {:ok, udp} = :gen_udp.open(port, udp_options)
        {:ok, %State{:udp => udp, :ip => ip}}
    end

    def handle_info({:udp, socket, ip, port, data}, state) do
        IO.inspect([ip, port, data])
        if ip != state.ip do
            Task.Supervisor.start_child(DatagramSupervisor, fn ->
                process(ip, port, data)
            end)
            :inet.setopts(socket, [active: 1])
        end
        {:noreply, state}
    end

    def handle_call({:send, message}, _from, state) do
        data = Poison.encode!(%Message{message | :ip => nil})
        :ok = :gen_udp.send(state.udp, message.ip, @port, data)
        {:reply, :ok, state}
    end

end
