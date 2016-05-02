defmodule Nodeponics.NodeSupervisor do
    use Supervisor

    @name __MODULE__

    def start_link do
        Supervisor.start_link(@name, :ok, name: @name)
    end

    def init(:ok) do
        children = [
            worker(Nodeponics.Node, [], restart: :transient)
        ]
        supervise(children, strategy: :simple_one_for_one)
    end

    def start_node(message) do
        Supervisor.start_child(@name, [message])
    end
end
