defmodule Nodeponics.WWW do

    alias Nodeponics.WWW

    def start_link do
        dispatch = :cowboy_router.compile([
            { :_,
                [
                    {"/", :cowboy_static, {:priv_file, :nodeponics, "index.html"}},
                    {"/static/[...]", :cowboy_static, {:priv_dir,  :nodeponics, "static_files"}},
                    {"/api", WWW.APIHandler, []},
                    {"/ws", WWW.Websocket, []}
            ]}
        ])
        {:ok, _} = :cowboy.start_http(:http,
            100,
            [{:port, 8080}],
            [{ :env, [{:dispatch, dispatch}]}]
        )
    end
end
