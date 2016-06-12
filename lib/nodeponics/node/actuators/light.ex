defmodule Nodeponics.Node.Actuator.Light do
    use Nodeponics.Node.Trigger.Clock,
        start_hour: 11,
        end_hour: 23,
        on_callback: "lighton",
        off_callback: "lightoff",
        thing: "light"
end
