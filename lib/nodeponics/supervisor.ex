defmodule Nodeponics.Supervisor do
    use Supervisor

    @name __MODULE__

    def start_link do
        Supervisor.start_link(__MODULE__, :ok, name: @name)
    end

    def init(:ok) do
        children = [
            worker(Nodeponics.UDPServer, []),
            worker(Nodeponics.TCPServer, []),
            #worker(Nodeponics.UPNPServer, []),
            supervisor(Task.Supervisor, [[name: Nodeponics.DatagramSupervisor]]),
            supervisor(Nodeponics.NodeSupervisor, []),
        ]
        supervise(children, strategy: :one_for_one)
    end
end
