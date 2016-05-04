defmodule WebsocketHandler do
    @behaviour :cowboy_websocket_handler

    alias Nodeponics.UDPServer.Message
    alias Nodeponics.Node

    def init({tcp, http}, _req, _opts) do
        {:upgrade, :protocol, :cowboy_websocket}
    end

    def websocket_init(_TransportName, req, _opts) do
        IO.puts "init.  Starting timer. PID is #{inspect(self())}"

        :erlang.start_timer(1000, self(), [])
        {:ok, req, :undefined_state }
    end

  # Required callback.  Put any essential clean-up here.
    def websocket_terminate(_reason, _req, _state) do
        :ok
    end

    def websocket_handle({:text, data}, req, state) do
        message = data |> Poison.decode!(as: %Message{})
        message = %{message | :id => String.to_atom(message.id)}
        Node.light(message.id, message.data)
        IO.inspect message
        {:reply, {:text, "yeah"}, req, state}
    end

    # Fallback clause for websocket_handle.  If the previous one does not match
    # this one just returns :ok without taking any action.  A proper app should
    # probably intelligently handle unexpected messages.
    def websocket_handle(_data, req, state) do
        {:ok, req, state}
    end

    # websocket_info is the required callback that gets called when erlang/elixir
    # messages are sent to the handler process.  In this example, the only erlang
    # messages we are passing are the :timeout messages from the timing loop.
    #
    # In a larger app various clauses of websocket_info might handle all kinds
    # of messages and pass information out the websocket to the client.
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
