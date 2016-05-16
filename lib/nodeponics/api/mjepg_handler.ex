defmodule Nodeponics.API.MJPEGHandler do
    require Logger

    alias Nodeponics.Node
    alias Nodeponics.Node.Event
    @boundary "boundarydonotcross"

    def delimiter do
        "\r\n--#{@boundary}\r\n"
    end

    def image_headers(image) do
        size = byte_size(image)
        "Content-Length: #{size}\r\nContent-Type: image/jpeg\r\n\r\n"
    end

    defmodule Handler do

        defmodule State do
            defstruct [:req]
        end

        def init(req) do
            {:ok, %State{:req => req}}
        end

        def handle_event(event = %Event{:type => :clock}, state) do
            {:ok, state}
        end

        def handle_event(event = %Event{:type => :image}, state) do
            msg = [
                Nodeponics.API.MJPEGHandler.image_headers(event.value),
                event.value,
                Nodeponics.API.MJPEGHandler.delimiter
            ]
            :cowboy_req.chunk(msg, state.req)
            {:ok, state}
        end

        def handle_event(event = %Event{}, state) do
            {:ok, state}
        end

    end

    def init({:tcp, :http}, req, opts) do
        Logger.info("MJPEG")
        {:ok, req, opts}
    end

    def handle(req, state) do
        {method, req} = :cowboy_req.method(req)
        {node_id, req} = :cowboy_req.qs_val("node_id", req)
        {user_id, req} = :cowboy_req.qs_val("user_id", req)
        node = String.to_atom(node_id)
        id = "#{user_id}:#{node_id}"
        Logger.info "Getting Stream for: #{id}"
        {:ok, req} = get_stream(method, node, id, req)
        Logger.info("Streaming Images")
        {:ok, req, state}
    end

    def get_stream("GET", node, id, req) do
        headers = [
            {"cache-control", "no-store, no-cache, must-revalidate, pre-check=0, post-check=0, max-age=0"},
            {"connection", "close"},
            {"content-type", "multipart/x-mixed-replace;boundary=--#{@boundary}"},
            {"expires", "Mon, 3 Jan 2000 12:34:56 GMT"},
            {"pragma", "no-cache"},
        ]
        {:ok, req2} = :cowboy_req.chunked_reply(200, headers, req)
        send_first_image(req2, node)
        stream(req2, node, id)
        {:ok, req2}
    end

    def send_first_image(req, node) do
        Logger.info("Getting First Image")
        img = Node.current_image(node)
        headers = image_headers(img)
        d = delimiter
        IO.inspect img
        IO.inspect headers
        IO.inspect d
        msg = [d, headers, img, d]
        :cowboy_req.chunk(msg, req)
    end

    def stream(req, node, id) do
        Logger.info("Stream")
        Node.add_event_handler(node, {Handler, id}, req)
    end

end
