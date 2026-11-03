local messages, callbacks, unsubscribed = {}, {}, {}
print = function(message) messages[#messages + 1] = message end
local function event(name)
    return {
        Subscribe = function(ref, callback) callbacks[name] = callback end,
        Unsubscribe = function(ref) unsubscribed[name] = ref end,
    }
end
Event = { Logic = event("logic"), GameStateChanged = event("state") }
package.loaded.probe = { update = function() end }
dofile("main.lua")
callbacks.state({ oldState = 30, newState = 20 })
assert(messages[2]:find("30 -> 20", 1, true))
PluginShutdown()
assert(messages[3]:find("shutting down", 1, true))
assert(unsubscribed.logic == "supplyCheck.probe")
assert(unsubscribed.state == "supplyCheck.state")
