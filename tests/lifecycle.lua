local callbacks, unsubscribed, snapshots = {}, {}, {}
local reads, failRefresh = 0, false
local function event(name)
    return {
        Subscribe = function(ref, callback) callbacks[name] = callback end,
        Unsubscribe = function(ref) unsubscribed[name] = ref end,
    }
end
Event = { ServerLogic = event("server"), GameStateChanged = event("state"),
    ContentLayerReady = event("content") }
package.loaded["inventory-reader"] = { read = function()
    reads = reads + 1
    return { backpack = { available = true }, equipment = { available = true } }
end }
package.loaded["supply-view"] = { build = function() return function(snapshot)
    if failRefresh then error("disposed panel") end
    snapshots[#snapshots + 1] = snapshot
end end }
dofile("main.lua")
callbacks.content({ component = {} })
assert(snapshots[1].backpack.available)
callbacks.state({ newState = 40 })
assert(not snapshots[2].backpack.available and not snapshots[2].equipment.available)
local readsBefore = reads
callbacks.server()
assert(not snapshots[3].backpack.available)
assert(reads == readsBefore, "must not read sources outside the game")
callbacks.state({ newState = 30 })
assert(snapshots[4].backpack.available)
failRefresh = true
callbacks.server()
readsBefore = reads
callbacks.server()
assert(reads == readsBefore, "failed panel should stop refreshing")
failRefresh = false
callbacks.content({ component = {} })
assert(snapshots[5].backpack.available, "reopened panel should read fresh data")
PluginShutdown()
assert(unsubscribed.server == "supplyCheck.refresh")
assert(unsubscribed.state == "supplyCheck.state")
assert(unsubscribed.content == "supplyCheck.content")
print("Panel lifecycle tests passed.")
