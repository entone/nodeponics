defmodule Nodeponics.API.Node do
    require Logger
    alias Nodeponics.NodeSupervisor
    alias Nodeponics.Node

    defmodule State do
        defstruct [:user]
    end

    def init({:tcp, :http}, req, opts) do
        {user_id, req} = :cowboy_req.qs_val("user_id", req)
        {:ok, req, %State{:user => user_id}}
    end

    def handle(req, state) do
        {user_id, req} = :cowboy_req.qs_val("user_id", req)
        Logger.info "Getting Nodes for #{state.user}"
        nodes = Enum.map(Supervisor.which_children(NodeSupervisor), fn({_id, pid, _type, module} = node) ->
             Node.id(pid) |> Atom.to_string
        end)
        IO.inspect nodes
        headers = [
            {"cache-control", "no-cache"},
            {"connection", "close"},
            {"content-type", "application/json"},
            {"expires", "Mon, 3 Jan 2000 12:34:56 GMT"},
            {"pragma", "no-cache"},
        ]
        {:ok, resp} = Poison.encode(%{:nodes => nodes})
        {:ok, req2} = :cowboy_req.reply(200, headers, resp, req)
        {:ok, req2, state}
    end

    def terminate(_reason, req, state) do
        :ok
    end

end
