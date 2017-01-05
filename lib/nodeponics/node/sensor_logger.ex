defmodule Nodeponics.Node.SensorLogger do
    use GenEvent
    use Timex
    require Logger
    alias Nodeponics.Event

    @sensor_keys Application.get_env(:nodeponics, :sensor_keys)

    defmodule State do
        defstruct [:id, dets: nil, lasts: %{}, refresh: 600]
    end

    def init(id) do
        {:ok, %State{:id => id}}
    end

    def handle_event(%Event{:type => type, :value => value}, state) do
        t = Enum.any?(@sensor_keys, fn(k) -> k == type end)
        new_state =
            case t do
                true -> check_interval(type, value, state)
                false -> state
        end
        {:ok, new_state}
    end

    def handle_event(%Event{}, state) do
        {:ok, state}
    end

    defp check_interval(type, value, state) do
        now = DateTime.universal
        diff =
            case Map.get(state.lasts, type) do
                %DateTime{} ->
                    DateTime.diff(now, Map.get(state.lasts, type), :seconds)
                nil ->
                    100000
            end
        cond do
            diff >= state.refresh ->
                :ok = write_data(type, value, now, state.id)
                %State{state | :lasts => Map.merge(state.lasts, %{type => now})} |> IO.inspect
            true ->
                state
        end
    end

    defp write_data(type, value, now, id) do
        obj = {type, value, now}
        Logger.info("Writing: #{inspect obj}")
        #dets = open_logging(id)
        #case :dets.insert(dets, obj) do
        #    :ok ->
        #        :dets.close(dets)
        #        :ok
        #    {:error, reason} ->
        #        Logger.info reason
        #        :dets.close(dets)
        #        :error
        #end
        :ok
    end

    def open_logging(id) do
        Logger.info("Opening DETS...")
        case :dets.open_file("/root/#{id}", [type: :bag, access: :read_write]) do
            {:ok, dets} -> dets
            {:EXIT, _} ->
                Logger.info("Error opening DETS... repairing")
                :timer.sleep(200)
                open_logging(id)
        end
    end
end
