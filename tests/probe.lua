local messages = {}
local originalPrint = print
print = function(message) messages[#messages + 1] = message end
local probe = require("probe")
config = { Inv = { INV = "backpack", WORN = "worn" } }
local sources = {
    backpack = { isValid = true, slotCount = 28, usedSlotCount = 1,
        GetSlots = function() return { [2] = { obj = { id = 565 }, count = 100 } } end },
    worn = { isValid = true, slotCount = 14, usedSlotCount = 1,
        GetSlots = function() return { [3] = { obj = { id = 882 }, count = 50 } } end },
}
Inventory = { Find = function(binding) return sources[binding] end }
probe.update()
assert(#messages == 2)
assert(messages[1]:find("slot=2 id=565 count=100", 1, true))
assert(messages[2]:find("slot=3 id=882 count=50", 1, true))
probe.update()
assert(#messages == 2)
sources.worn.isValid = false
probe.update()
assert(#messages == 3 and messages[3]:find("inventory invalid", 1, true))
sources.worn.isValid = true
sources.worn.GetSlots = function() error("test failure") end
probe.update()
assert(#messages == 4 and messages[4]:find("read failed", 1, true))
sources.worn.GetSlots = function() return nil end
probe.update()
assert(#messages == 5 and messages[5]:find("GetSlots unavailable", 1, true))
config.Inv.WORN = nil
probe.update()
assert(#messages == 6 and messages[6]:find("config.Inv.WORN unavailable", 1, true))
print = originalPrint
print("Diagnostic probe mock tests passed.")
