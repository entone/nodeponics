defmodule Nodeponics.TCPServer do

    alias Nodeponics.API
    alias Nodeponics.Websocket

    @port Application.get_env(:nodeponics, :tcp_port)

    def start_link do
        dispatch = :cowboy_router.compile([
            { :_,
                [
                    {"/", :cowboy_static, {:priv_file, :nodeponics, "index.html"}},
                    {"/static/[...]", :cowboy_static, {:priv_dir,  :nodeponics, "static"}},
                    {"/ws", API.Websocket, []},
                    {"/stream", API.MJPEGHandler, []},
                    {"/nodes", API.Node, []},
            ]}
        ])
        {:ok, _} = :cowboy.start_http(:http,
            100,
            [{:port, @port}],
            [{:env, [{:dispatch, dispatch}]}]
        )
    end
end
