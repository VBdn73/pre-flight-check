local reader = require("inventory-reader")
local view = require("supply-view")
local refreshContent
local canRead = true

local function refresh()
    if not refreshContent then return end
    local snapshot = canRead and reader.read() or {
        backpack = { available = false }, equipment = { available = false },
    }
    local ok, err = pcall(refreshContent, snapshot)
    if not ok then
        refreshContent = nil
        print("[supply-check] Panel refresh stopped: " .. tostring(err))
    end
end

Event.ContentLayerReady.Subscribe("supplyCheck.content", function(event)
    refreshContent = nil
    local ok, result = pcall(view.build, event.component)
    if not ok then
        print("[supply-check] Panel creation failed: " .. tostring(result))
        return
    end
    refreshContent = result
    refresh()
end)

Event.ServerLogic.Subscribe("supplyCheck.refresh", refresh)
Event.GameStateChanged.Subscribe("supplyCheck.state", function(event)
    canRead = event.newState == 30 -- GameState.GAME
    refresh()
end)

function PluginShutdown()
    refreshContent = nil
    Event.ContentLayerReady.Unsubscribe("supplyCheck.content")
    Event.ServerLogic.Unsubscribe("supplyCheck.refresh")
    Event.GameStateChanged.Unsubscribe("supplyCheck.state")
end
