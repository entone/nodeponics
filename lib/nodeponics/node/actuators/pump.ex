defmodule Nodeponics.Node.Actuator.Pump do
    use Nodeponics.Node.Trigger.Frequency,
        frequency: 900,
        runtime: 180,
        on_callback: "pumpon",
        off_callback: "pumpoff",
        thing: "pump"
end
