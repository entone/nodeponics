defmodule Nodeponics.Node.Clock do
    use GenServer
    use Timex
    alias Nodeponics.Node.Event

    def start_link(events) do
        GenServer.start_link(__MODULE__, events)
    end

    def init(events) do
        start_clock
        {:ok, events}
    end

    def handle_info(:clock, events) do
        GenEvent.notify(events, %Event{:type => :clock, :value => DateTime.universal})
        start_clock
        {:noreply, events}
    end

    def start_clock do
        Process.send_after(self, :clock, 1000)
    end
end
