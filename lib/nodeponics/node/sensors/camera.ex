defmodule Nodeponics.Node.Sensor.Camera do
    use GenServer
    require Logger
    alias Nodeponics.Node.Event

    defmodule State do
        defstruct [:url, :image, :events, refresh: 0]
    end

    def start_link(url, events) do
        GenServer.start_link(__MODULE__, [url, events])
    end

    def current_image(camera) do
        GenServer.call(camera, :current_image)
    end

    def get_image(url) do
        {:ok, resp} = :httpc.request(:get, {url, []}, [], [body_format: :binary])
         case resp do
            {{_, 200, 'OK'}, _headers, body} ->
                body
            {{_, _, _}, _headers, body} ->
                body
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

    def handle_call(:current_image, _from, state) do
        {:reply, state.image, state}
    end

    def handle_info(:image, state) do
        new_state = %State{state | :image => get_image(state.url)}
        GenEvent.notify(state.events, %Event{:type => :image, :value => new_state.image})
        get_images(state.refresh)
        {:noreply, new_state}
    end

end
