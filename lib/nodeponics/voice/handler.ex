defmodule Nodeponics.Voice.Handler do
    use GenEvent
    require Logger
    alias Movi.Event
    alias Nodeponics.Node

    @verbs Application.get_env(:movi, :verbs)
    @combinators Application.get_env(:movi, :combinators)
    @descriptors Application.get_env(:movi, :descriptors)
    @locations Application.get_env(:movi, :locations)
    @things Application.get_env(:movi, :things)
    @numbers Application.get_env(:movi, :numbers)

    def handle_event(event = %Event{:message => message}, state) when message != nil do
        IO.inspect event
        acc = %{:verbs => [], :combinators => [], :descriptors => [], :locations => [], :things => [], :numbers => []}
        Enum.reduce(message, acc, fn(word, acc) ->
            cond do
                Enum.find_index(@verbs, fn(x) -> x == word end) ->
                    %{acc | :verbs => List.insert_at(acc.verbs, -1, word)}
                Enum.find_index(@combinators, fn(x) -> x == word end) ->
                    %{acc | :combinators => List.insert_at(acc.combinators, -1, word)}
                Enum.find_index(@descriptors, fn(x) -> x == word end) ->
                    %{acc | :descriptors => List.insert_at(acc.descriptors, -1, word)}
                Enum.find_index(@locations, fn(x) -> x == word end) ->
                    %{acc | :locations => List.insert_at(acc.locations, -1, word)}
                Enum.find_index(@things, fn(x) -> x == word end) ->
                    %{acc | :things => List.insert_at(acc.things, -1, word)}
                Enum.find_index(@numbers, fn(x) -> x == word end) ->
                    %{acc | :numbers => List.insert_at(acc.numbers, -1, word)}
                true ->
                    acc
            end
        end) |> IO.inspect
        {:ok, state}
    end

end
