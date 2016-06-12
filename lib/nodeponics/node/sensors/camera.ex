defmodule Nodeponics.Node.Sensor.Camera do
    use GenServer
    require Logger
    alias Nodeponics.Event

    defmodule State do
        defstruct [:url, :events, image: "0", refresh: 0]
    end

    def start_link(url, events) do
        GenServer.start_link(__MODULE__, [url, events])
    end

    def add_event_handler(camera, handler, parent) do
        GenServer.call(camera, {:add_handler, handler, parent})
    end

    def get_image(url, state) do
        case HTTPoison.get(url) do
            {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
                body
            {:ok, %HTTPoison.Response{status_code: status, body: body}} ->
                Logger.debug "Error getting image. #{inspect body}"
                state.image
            {:error, _other} ->
                Logger.debug "Error getting image."
                state.image
        end
    end

    def get_images(refresh) do
        Process.send_after(self, :image, refresh)
    end

    def init([url, events]) do
        state = %State{:url => url, :events => events}
        Logger.info("Camera Started: #{state.url}")
        get_images(state.refresh)
        {:ok, state}
    end

    def handle_info(:image, state) do
        new_state = %State{state | :image => get_image(state.url, state)}
        GenEvent.notify(state.events, %Event{:type => :image, :value => new_state.image})
        get_images(state.refresh)
        {:noreply, new_state}
    end

end
