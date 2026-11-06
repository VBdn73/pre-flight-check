local probe = require("quiver-diagnostic")
config = { Inv = { INV = "INV", WORN = "WORN" } }
local slots = { { obj = { id = 52532 }, legacyvarobj = 916117607, vars = { objvar_1 = 1073759409 } } }
local inventories = {
    INV = { isValid = true, GetSlots = function() return slots end },
    WORN = { isValid = true, GetSlots = function() return {} end },
}
Inventory = { Find = function(name) return inventories[name] end }
local text = probe.read()
assert(text:find("legacyvarobj=916117607 objvar_1=1073759409", 1, true))
assert(text:find("WORN: no Pernix quiver found", 1, true))
slots = { { obj = { id = 52580 } } }
assert(probe.read():find("legacyvarobj=not exposed objvar_1=not exposed", 1, true))
inventories.WORN.isValid = false
assert(probe.read():find("WORN: unavailable", 1, true))
inventories.INV.GetSlots = function() error("test failure") end
assert(probe.read():find("INV: read failed", 1, true))
local messages, originalPrint = {}, print
print = function(message) messages[#messages + 1] = message end
probe.update(); probe.update()
assert(#messages == 1)
probe.reset(); probe.update()
assert(#messages == 2)
print = originalPrint
print("Quiver diagnostic mock tests passed.")
