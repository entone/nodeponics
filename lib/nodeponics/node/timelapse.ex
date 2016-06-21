defmodule Nodeponics.Node.Timelapse do
    use GenEvent
    use Timex

    defmodule State do
        defstruct [:last, refresh: 10000]
    end

    def init(:ok) do
        {:ok, %State{:last => DateTime.universal}}
    end

    def handle_event(%Event{:type => :image, :value => image}, state) do
        now = DateTime.universal
        diff = DateTime.diff(now, state.last, :seconds)
        save_image(diff)
        new_state = cond diff do
            diff > state.refresh ->
                save_image(image)
                %State{state | :last => DateTime.universal}
            true ->
                state
        end
        {:ok, new_state}
    end
end
