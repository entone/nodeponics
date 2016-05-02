defmodule Nodeponics.UDPServer do
    use GenServer
    require Logger

    defmodule Message do
        defstruct [:id, :type, :data, :ip, :port]
    end

    @init "init"
    @port Application.get_env(:nodeponics, :port)

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
        Logger.info "Accepting datagrams on port: #{port}"
        :gen_udp.open(port, [:binary, active: 10])
    end

    def handle_info({:udp, socket, ip, port, data}, state) do
        Logger.info "Processing:"
        IO.inspect([ip, port, data])
        {:ok, _pid} = Task.Supervisor.start_child(Nodeponics.DatagramSupervisor, fn ->
            process(ip, port, data)
        end)
        :inet.setopts(socket, [active: 1])
        {:noreply, state}
    end

    def handle_call({:send, message}, _from, state) do
        data = Poison.encode!(%Message{message | :ip => nil})
        :ok = :gen_udp.send(state, message.ip, @port, data)
        {:reply, :ok, state}
    end

end
