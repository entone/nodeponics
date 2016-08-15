defmodule Nodeponics.UDPServer do
    use GenServer
    require Logger
    alias Nodeponics.DatagramSupervisor
    alias Nodeponics.Message

    defmodule WifiHandler do
        use GenEvent
        def init(parent) do
            {:ok, %{:parent => parent}}
        end

        def handle_event({:udhcpc, _, :bound, info}, state) do
            Logger.info "Wifi bound: #{inspect info}"
            send(state.parent, {:bound, info})
            {:ok, state}
        end

        def handle_event(ev, state) do
            {:ok, state}
        end
    end

    @cipher_key Application.get_env(:nodeponics, :cipher_key) <> <<0>>

    defmodule State do
        defstruct [:ip, :udp, :port]
    end

    @port Application.get_env(:nodeponics, :udp_port)
    @multicast Application.get_env(:nodeponics, :multicast_address)
    @interfaces ['wlan0', 'eth0']

    def start_link do
        GenServer.start(__MODULE__, @port, name: __MODULE__)
    end

    def send_message(message) do
        GenServer.call(__MODULE__, {:send, message})
    end

    def process(ip, port, data) do
        data |> decrypt |> deserialize(ip, port) |> handle
    end

    def decrypt(data) when data |> is_binary do
        << iv :: binary-size(16), message :: binary >> = data
        :crypto.block_decrypt(:aes_cbc128, @cipher_key, iv, message) |> :binary.split(<<0>>) |> List.first
    end

    def deserialize(data, ip, port) do
        message = data |> Poison.decode!(as: %Message{})
        %Message{message | :ip => ip, :port => port, :id => String.to_atom(message.id)}
    end

    def handle(message = %Message{}) do
        case Process.whereis(message.id) do
            nil -> Nodeponics.NodeSupervisor.start_node(message)
            _ -> true
        end
        Nodeponics.Node.update_state(message.id, message)
        send(message.id, message)
    end

    def init(port) do
        Logger.info "Opening UDP"
        Logger.info @cipher_key
        intfs =
            :inet.getifaddrs()
            |> elem(1)
            |> Enum.find(fn(inf) ->
                Enum.member?(@interfaces, elem(inf, 0))
            end)
            |> elem(1)
        ip = intfs[:addr]
        udp_options = [
            :binary,
            active:          10,
            add_membership:  { @multicast, {0,0,0,0} },
            multicast_if:    {0,0,0,0},
            multicast_loop:  true,
            multicast_ttl:   4,
            reuseaddr:       true
        ]
        {:ok, udp} = :gen_udp.open(port, udp_options)
        {:ok, %State{:port => port, :ip => ip, :udp => udp}}
    end

    def handle_info({:udp, socket, ip, port, data}, state) do
        if ip != state.ip do
            Task.Supervisor.start_child(DatagramSupervisor, fn ->
                process(ip, port, data)
            end)
        end
        :inet.setopts(socket, [active: 1])
        {:noreply, state}
    end

    def handle_call({:send, message}, _from, state) do
        data = "#{message.type}:#{message.data}:#{message.id}\n"
        :ok = :gen_udp.send(state.udp, message.ip, @port, data)
        {:reply, :ok, state}
    end

end
