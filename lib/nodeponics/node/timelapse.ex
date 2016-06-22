defmodule Nodeponics.Node.Timelapse do
    use GenEvent
    use Timex
    alias ExAws.{S3, Operation}
    alias Nodeponics.Event

    defmodule State do
        defstruct [:last, :id, refresh: 600]
    end

    def init(id) do
        create_bucket(id)
        {:ok, %State{:last => DateTime.universal, :id => id}}
    end

    def handle_event(%Event{:type => :image, :value => image}, state) do
        now = DateTime.universal
        diff = DateTime.diff(now, state.last, :seconds)
        cond do
            diff > state.refresh ->
                :ok = save_image(image, state.id, now)
                {:ok, %State{state | :last => DateTime.universal}}
            true ->
                {:ok, state}
        end
    end

    def handle_event(%Event{}, state) do
        {:ok, state}
    end

    def create_bucket(id) do
        case S3.put_bucket(id, "us-west-2") do
            {:ok, content} ->
                IO.inspect content
                :ok
            {:error, info} ->
                IO.inspect info
                :error
        end
    end

    def save_image(image, id, datetime) do
        {:ok, date_str} = Timex.format(datetime, "{YYYY}{M}{D}{h24}{m}{s}")
        case S3.put_object(id, "#{date_str}.jpeg", image, [{:content_type, "image/jpeg"}, {:acl, :public_read}]) do
            {:ok, content} ->
                IO.inspect content
                :ok
            {:error, info} ->
                IO.inspect info
                :ok
        end
    end
end
