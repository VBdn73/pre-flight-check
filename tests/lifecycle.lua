local callbacks, unsubscribed, snapshots = {}, {}, {}
local reads = 0
local function event(name)
    return {
        Subscribe = function(ref, callback) callbacks[name] = callback end,
        Unsubscribe = function(ref) unsubscribed[name] = ref end,
    }
end
Event = { ServerLogic = event("server"), GameStateChanged = event("state"),
    Logic = event("logic"), SettingsLayerReady = event("settings"), ContentLayerReady = event("content"), MiniMenuEntrySelected = event("menu"),
    VarTransmit = event("var"), KeyDown = event("key"), ChatMessage = event("chat") }
local rules, manualClick, buttonVisible = {}, nil, false
package.loaded["warnings/settings"] = { load = function() return rules end }
package.loaded["warnings/check-button"] = {
    update = function(enabled, callback) buttonVisible = enabled; manualClick = callback end,
    close = function() buttonVisible = false end,
}
local settingsDestroyed, settingsRefreshes = 0, 0
package.loaded["warnings/settings-view"] = { build = function()
    return function()
        settingsRefreshes = settingsRefreshes + 1
        error("simulated settings failure")
    end, function() settingsDestroyed = settingsDestroyed + 1 end
end }
package.loaded["warnings/monitor"] = { new = function() return {
    update = function(snapshot) snapshots[#snapshots + 1] = snapshot; return {} end } end }
package.loaded["warnings/popup"] = { clear = function() end, update = function() end }
package.loaded["supplies/inventory-reader"] = { read = function()
    reads = reads + 1
    return { backpack = { available = true }, equipment = { available = true } }
end }
dofile("main.lua")
-- Updates without an enabled trigger and updates outside the game.
callbacks.logic({ logicTick = 50 })
callbacks.server()
assert(#snapshots == 0, "server updates alone do not check warnings")
callbacks.state({ newState = 40 })
local readsBefore = reads
callbacks.server()
assert(reads == readsBefore, "must not read sources outside the game")
assert(#snapshots == 0, "must not monitor sources outside the game")
callbacks.state({ newState = 30 })
assert(#snapshots == 0, "entering the game does not check warnings")
callbacks.server()
assert(#snapshots == 0, "warnings only run after an enabled action")
rules.showCheckButton = true
callbacks.logic({ logicTick = 100 })
assert(buttonVisible)
manualClick()
assert(#snapshots == 1, "manual checks work with every automatic trigger disabled")
rules.showCheckButton = false
manualClick()
assert(#snapshots == 1, "disabled button cannot trigger checks")
rules.showCheckButton = true
callbacks.state({ newState = 40 })
assert(not buttonVisible)
manualClick()
assert(#snapshots == 1, "manual checks do not read outside the game")
-- Refresh failures report the reason instead of silently blanking settings.
local originalPrint, diagnostic = print
print = function(message) diagnostic = message end
callbacks.settings({ component = {} })
callbacks.logic({ logicTick = 101 })
print = originalPrint
assert(diagnostic:find("Settings refresh failed:", 1, true)
    and diagnostic:find("simulated settings failure", 1, true))
assert(settingsDestroyed == 1 and settingsRefreshes == 1)
callbacks.logic({ logicTick = 102 })
assert(settingsRefreshes == 1, "failed settings must not refresh again")
-- Shutdown unregisters each event subscription.
PluginShutdown()
assert(unsubscribed.server == "supplyCheck.refresh")
assert(unsubscribed.state == "supplyCheck.state")
assert(unsubscribed.logic == "supplyCheck.clock")
assert(unsubscribed.settings == "supplyCheck.settings")
assert(unsubscribed.content == "supplyCheck.content")
assert(unsubscribed.menu == "supplyCheck.preset")
assert(unsubscribed.key == "supplyCheck.presetShortcut")
assert(unsubscribed.chat == "supplyCheck.presetMessages")
print("Plugin lifecycle tests passed.")
