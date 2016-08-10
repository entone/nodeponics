defmodule Nodeponics.API.Timelapse do
    require Logger

    alias ExAws.{S3, Operation}
    alias Nodeponics.Node
    alias Nodeponics.Event
    @boundary "boundarydonotcross"

    def delimiter do
        "\r\n--#{@boundary}\r\n"
    end

    def image_headers(image) do
        size = byte_size(image)
        "Content-Type: image/jpeg\r\nContent-Length: #{size}\r\n\r\n"
    end

    defmodule ImageDownloader do
        use GenServer
        use Timex

        defmodule State do
            defstruct [:parent, :prefix, :id]
        end

        def start_link([parent, prefix, id]) do
            GenServer.start_link(__MODULE__, [parent, prefix, id])
        end

        def init([parent, prefix, id]) do
            Process.send_after(self(), :download, 100)
            {:ok, %State{:parent => parent, :prefix => prefix, :id => id}}
        end

        def handle_info(:download, state) do
            url = "https://s3-us-west-2.amazonaws.com/#{state.id}/"
            S3.stream_objects!(state.id, [prefix: state.prefix])
            |> Enum.each(fn(image) ->
                IO.inspect image.key
                value = get_image(url <> image.key)
                send(state.parent, {:image, value})
            end)
            {:noreply, state}
        end

        def get_image(url) do
            case HTTPoison.get(url) do
                {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
                    body
                {:ok, %HTTPoison.Response{status_code: status, body: body}} ->
                    Logger.debug "Error getting image. #{inspect body}"
                    ""
                {:error, _other} ->
                    Logger.debug "Error getting image."
                    ""
            end
        end

    end

    def init({:tcp, :http}, req, opts) do
        {method, req} = :cowboy_req.method(req)
        {node_id, req} = :cowboy_req.qs_val("node_id", req)
        {user_id, req} = :cowboy_req.qs_val("user_id", req)
        node = String.to_atom(node_id)
        id = "#{user_id}:#{node_id}"
        Logger.info "Getting Stream for: #{id}"
        headers = [
            {"cache-control", "no-cache"},
            {"connection", "close"},
            {"content-type", "multipart/x-mixed-replace;boundary=#{@boundary}"},
            {"expires", "Mon, 3 Jan 2000 12:34:56 GMT"},
            {"pragma", "no-cache"},
        ]
        {:ok, req2} = :cowboy_req.chunked_reply(200, headers, req)
        stream(node, id)
        {:loop, req2, []}
    end

    def info({:image, value}, req, state) do
        msg = image_headers(value)
            <> value
            <> delimiter
        :cowboy_req.chunk(msg, req)
        {:loop, req, state}
    end

    def info(_, req, state) do
        {:loop, req, state}
    end

    def stream(node, id) do
        n = Atom.to_string(node)
        ImageDownloader.start_link([self(), "20167", n])
    end

    def terminate(reason, req, state) do
        :ok
    end

end
