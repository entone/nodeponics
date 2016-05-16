defmodule Nodeponics.TCPServer do

    alias Nodeponics.API
    alias Nodeponics.Websocket

    @port Application.get_env(:nodeponics, :tcp_port)

    def start_link do
        dispatch = :cowboy_router.compile([
            { :_,
                [
                    {"/", :cowboy_static, {:priv_file, :nodeponics, "index.html"}},
                    {"/static/[...]", :cowboy_static, {:priv_dir,  :nodeponics, "static_files"}},
                    {"/api", API.APIHandler, []},
                    {"/ws", Websocket.Node, []},
                    {"/stream", API.MJPEGHandler, []}
            ]}
        ])
        {:ok, _} = :cowboy.start_http(:http,
            100,
            [{:port, @port}],
            [{ :env, [{:dispatch, dispatch}]}]
        )
    end
end
