local callbacks, unsubscribed, snapshots = {}, {}, {}
local reads = 0
local function event(name)
    return {
        Subscribe = function(ref, callback) callbacks[name] = callback end,
        Unsubscribe = function(ref) unsubscribed[name] = ref end,
    }
end
Event = { ServerLogic = event("server"), GameStateChanged = event("state"),
    Logic = event("logic"), SettingsLayerReady = event("settings"), MiniMenuEntrySelected = event("menu"),
    VarTransmit = event("var"), KeyDown = event("key") }
package.loaded["warnings/settings"] = { load = function() return {} end }
package.loaded["warnings/settings-view"] = { build = function() end }
package.loaded["warnings/monitor"] = { new = function() return {
    update = function(snapshot) snapshots[#snapshots + 1] = snapshot; return {} end,
    reset = function() end } end }
package.loaded["warnings/popup"] = { clear = function() end, update = function() end }
package.loaded["inventory-reader"] = { read = function()
    reads = reads + 1
    return { backpack = { available = true }, equipment = { available = true } }
end }
dofile("main.lua")
callbacks.logic({ logicTick = 50 })
callbacks.server()
assert(snapshots[1].backpack.available)
callbacks.state({ newState = 40 })
local readsBefore = reads
callbacks.server()
assert(reads == readsBefore, "must not read sources outside the game")
assert(#snapshots == 1, "must not monitor sources outside the game")
callbacks.state({ newState = 30 })
assert(snapshots[2].backpack.available)
callbacks.server()
assert(#snapshots == 3, "warnings continue without a ribbon panel")
PluginShutdown()
assert(unsubscribed.server == "supplyCheck.refresh")
assert(unsubscribed.state == "supplyCheck.state")
assert(unsubscribed.logic == "supplyCheck.clock")
assert(unsubscribed.settings == "supplyCheck.settings")
assert(unsubscribed.menu == "supplyCheck.preset")
assert(unsubscribed.key == "supplyCheck.presetShortcut")
print("Plugin lifecycle tests passed.")
