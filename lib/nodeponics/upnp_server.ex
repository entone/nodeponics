defmodule Nodeponics.UPNPServer do
    use GenServer
    require Logger

    import SweetXml

    @port 1900
    @multicast_group {239,255,255,250}

    def discover_message do
        "M-SEARCH * HTTP/1.1\r\nHOST: 239.255.255.250:1900\r\nMAN: \"ssdp:discover\"\r\nMX: 1\r\nST: ssdp:all\r\n\r\n"
    end

    def start_link do
        GenServer.start(__MODULE__, @port, name: __MODULE__)
    end

    def discover do
        Process.send_after(self, :discover, 100)
    end

    def init(port) do
        udp_options = [
            :binary,
            active:          10,
            add_membership:  { @multicast_group, {0,0,0,0} },
            multicast_if:    {0,0,0,0},
            multicast_loop:  false,
            multicast_ttl:   4,
            reuseaddr:       true
        ]
        discover
        {:ok, udp} = :gen_udp.open(port, udp_options)
    end

    def handle_info(:discover, state) do
        m = discover_message
        Logger.info "Sending Discovery: #{m}"
        :gen_udp.send(state, @multicast_group, @port, m)
        Process.send_after(self, :discover, 10000)
        {:noreply, state}
    end

    @msearch "M-SEARCH * HTTP/1.1"
    def handle_info({:udp, _s, ip, port, <<@msearch, rest :: binary>>}, state) do
        IO.inspect rest
        IO.inspect ip
        raw_params = String.split(rest, ["\r\n", "\n"])
        mapped_params = Enum.map raw_params, fn(x) ->
            case String.split(x, ":", parts: 2) do
                [k, v] -> {String.to_atom(String.downcase(k)), String.strip(v)}
                _ -> nil
            end
        end
        resp = Enum.reject mapped_params, &(&1 == nil)
        IO.inspect Dict.merge(%{}, resp)
        {:noreply, state}
    end

    @msearch_reponse "HTTP/1.1 200 OK"
    def handle_info({:udp, _s, ip, port, <<@msearch_reponse, rest :: binary>>}, state) do
        raw_params = String.split(rest, ["\r\n", "\n"])
        mapped_params = Enum.map raw_params, fn(x) ->
            case String.split(x, ":", parts: 2) do
                [k, v] -> {String.to_atom(String.downcase(k)), String.strip(v)}
                _ -> nil
            end
        end
        resp = Enum.reject mapped_params, &(&1 == nil)
        res = Dict.merge(%{}, resp)
        case HTTPoison.get(Dict.get(resp, :location), [], hackney: [:insecure]) do
            {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
                f_name = body |> xpath(~x"//device/friendlyName/text()")
                m_name = body |> xpath(~x"//device/modelName/text()")
                Logger.info "Found #{f_name} (#{m_name}) on local network"
            {:ok, %HTTPoison.Response{status_code: 404}} ->
                IO.puts "Not found :("
            {:error, %HTTPoison.Error{reason: reason}} ->
                IO.inspect reason
        end

        {:noreply, state}
    end

    def handle_info({:udp, _s, _ip, _port, _}, state), do: {:noreply, state}
    def handle_info({:udp_passive, _}, state), do: {:noreply, state}
end
