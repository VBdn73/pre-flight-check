local probe = require("probe")

print("[supply-check] Data-source diagnostic started; changes are logged to the plugin console.")
Event.Logic.Subscribe("supplyCheck.probe", function()
    probe.update()
end)

Event.GameStateChanged.Subscribe("supplyCheck.state", function(event)
    print("[supply-check] Game state: " .. tostring(event.oldState)
        .. " -> " .. tostring(event.newState))
end)

function PluginShutdown()
    print("[supply-check] Diagnostic shutting down.")
    Event.Logic.Unsubscribe("supplyCheck.probe")
    Event.GameStateChanged.Unsubscribe("supplyCheck.state")
end
