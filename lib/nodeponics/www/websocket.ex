defmodule Nodeponics.WWW.Websocket do
    @behaviour :cowboy_websocket_handler
    require Logger

    alias Nodeponics.Node
    alias Nodeponics.Node.Event
    alias Nodeponics.UDPServer.Message

    defmodule State do
        defstruct [:node, :id]
    end

    defmodule NodeHandler do

        defmodule State do
            defstruct [:parent]
        end

        def init(parent) do
            {:ok, %State{:parent => parent}}
        end

        def handle_event(event = %Event{}, state) do
            send(state.parent, event)
            {:ok, state}
        end

        def handle_event(event = %Event{:type => :clock}, state) do
            {:ok, state}
        end

    end

    def init({tcp, http}, _req, _opts) do
        {:upgrade, :protocol, :cowboy_websocket}
    end

    def websocket_init(_TransportName, req, _opts) do
        {node_id, req} = :cowboy_req.qs_val("node_id", req)
        {user_id, req} = :cowboy_req.qs_val("user_id", req)
        id = "#{user_id}:#{node_id}"
        :erlang.start_timer(1000, self(), [])
        node = String.to_atom(node_id)
        Node.add_event_handler(node, {NodeHandler, id}, self)
        Node.state(node)
        {:ok, req, %State{node: node, id: id}}
    end

    def websocket_terminate(_reason, _req, state) do
        Logger.info "Terminating Websocket #{state.id}"
        Node.remove_event_handler(state.node, {NodeHandler, state.id})
        :ok
    end

    def websocket_handle({:text, data}, req, state) do
        message = data |> Poison.decode!(as: %Message{})
        message = %{message | :id => state.node}
        Node.light(message.id, message.data)
        IO.inspect message
        {:reply, {:text, "yeah"}, req, state}
    end

    def websocket_handle(_data, req, state) do
        {:ok, req, state}
    end

    def websocket_info(event = %Event{}, req, state) do
        {:reply, {:text, Poison.encode!(event)}, req, state}
    end

    def websocket_info({timeout, _ref, _foo}, req, state) do
        time = time_as_string()

        # encode a json reply in the variable 'message'
        { :ok, message } = Poison.encode(%{ time: time})


        # set a new timer to send a :timeout message back to this process a second
        # from now.
        :erlang.start_timer(1000, self(), [])

        # send the new message to the client. Note that even though there was no
        # incoming message from the client, we still call the outbound message
        # a 'reply'.  That makes the format for outbound websocket messages
        # exactly the same as websocket_handle()
        { :reply, {:text, message}, req, state}
    end

    # fallback message handler
    def websocket_info(_info, req, state) do
        {:ok, req, state}
    end

    def time_as_string do
        {hh,mm,ss} = :erlang.time()
        :io_lib.format("~2.10.0B:~2.10.0B:~2.10.0B",[hh,mm,ss])
        |> :erlang.list_to_binary()
    end

end
