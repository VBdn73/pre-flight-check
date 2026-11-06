local callbacks = {}
local function event(name)
    return { Subscribe = function(_, cb) callbacks[name] = cb end, Unsubscribe = function() end }
end
Event = { Logic = event("logic"), ServerLogic = event("server"),
    GameStateChanged = event("state"),
    SettingsLayerReady = event("settings") }
local amount, available = 200, true
package.loaded["inventory-reader"] = { read = function()
    return { backpack = { available = available, counts = { [563] = amount } },
        equipment = { available = true, counts = {} }, runeCounts = available and { [563] = amount } or {} }
end }
package.loaded["warnings/settings"] = { effective = function(_, rule) return rule end, load = function() return {
    { itemId = 563, enabled = true, warnAtZero = false, low = 100, critical = 25,
        lowCooldown = 300, criticalCooldown = 60 } } end }
package.loaded["warnings/settings-view"] = { build = function() end }
local alerts, clears = {}, 0
package.loaded["warnings/popup"] = { show = function(items) alerts[#alerts + 1] = items; return true end,
    clear = function() clears = clears + 1 end, update = function() end }
dofile("main.lua")
callbacks.logic({ logicTick = 50 })
callbacks.server()
assert(#alerts == 0)
amount = 99
callbacks.server()
assert(#alerts == 1 and alerts[1][1].level == "low")
amount = 24
callbacks.server()
assert(#alerts == 2 and alerts[2][1].level == "critical")
available = false
callbacks.server()
assert(#alerts == 2 and clears > 0)
callbacks.state({ newState = 40 })
callbacks.server()
assert(#alerts == 2)
PluginShutdown()
print("Warning integration tests passed.")
