local callbacks = {}
local function event(name)
    return { Subscribe = function(_, cb) callbacks[name] = cb end, Unsubscribe = function() end }
end
Event = { Logic = event("logic"), ServerLogic = event("server"), GameStateChanged = event("state"),
    SettingsLayerReady = event("settings"), MiniMenuEntrySelected = event("menu"), KeyDown = event("key") }
local amount, available, bankOpen = 200, true, false
var = { VarPlayer = { BANK_ACTIVE = { value = 1 } } }
ui = { Interfaces = { GetInterface = function() return bankOpen and {} or nil end,
    GetComponent = function() return { visibleGlobal = true } end } }
package.loaded["inventory-reader"] = { read = function()
    return { backpack = { available = available, counts = {} }, equipment = { available = available, counts = {} },
        runeCounts = { [563] = amount } }
end }
local rules = { checkOnPreset = false, checkOnBankClose = false,
    { itemId = 563, enabled = true, warnAtZero = false, low = 100, critical = 25 } }
package.loaded["warnings/settings"] = { effective = function(_, rule) return rule end,
    load = function() return rules end }
package.loaded["warnings/settings-view"] = { build = function() end }
local alerts = {}
package.loaded["warnings/popup"] = { show = function(items) alerts[#alerts + 1] = items; return true end,
    clear = function() end, update = function() end }
dofile("main.lua")
local function time(seconds) callbacks.logic({ logicTick = seconds * 50 }) end
local function load() callbacks.menu({ entry = { verbText = "Load", componentData = { component = {
    interfaceID = 517, staticID = 267 } } } }) end
time(1)
callbacks.server()
amount = 99
time(2)
callbacks.server()
assert(#alerts == 0, "no continuous warnings")
load() -- disabled
time(4)
callbacks.server()
assert(#alerts == 0)
rules.checkOnPreset = true
load()
amount = 80 -- server data changes after action
time(5)
callbacks.server()
assert(#alerts == 0, "must wait for fresh server data")
time(6)
callbacks.server()
assert(#alerts == 1 and alerts[1][1].count == 80, "preset check uses fresh data")
load()
time(8)
callbacks.server()
assert(#alerts == 2, "repeated preset loads check again")
bankOpen = true
time(9)
callbacks.key({ gameKey = 16, modifiers = 0, isRepeat = false })
amount = 70
time(11)
callbacks.server()
assert(#alerts == 3 and alerts[3][1].count == 70, "shortcut schedules a check")
rules.checkOnPreset = false
rules.checkOnBankClose = true
bankOpen = false
time(12)
time(14)
callbacks.server()
assert(#alerts == 4, "bank closure schedules a check")
bankOpen = true
time(15)
bankOpen = false
time(16)
available = false
time(18)
callbacks.server()
assert(#alerts == 4, "unavailable inventory cannot trigger a check")
available = true
time(19)
callbacks.server()
assert(#alerts == 5, "pending check retries when inventory returns")
time(40)
callbacks.server()
assert(#alerts == 5, "server updates do not repeat alerts")
rules[1].enabled = false
rules.checkOnPreset = true
load()
time(42)
callbacks.server()
assert(#alerts == 5, "disabled items do not alert on a triggered check")
callbacks.state({ newState = 40 })
PluginShutdown()
print("Warning integration tests passed.")
