local diagnostic = require("rune-diagnostic")
config = { Inv = { INV = "INV", WORN = "WORN" } }
local inventories = {
    INV = { isValid = true, GetTotal = function(_, id) return id == 563 and 12 or 0 end },
    WORN = { isValid = true, GetTotal = function(_, id) return id == 52299 and 20 or 0 end },
}
Inventory = { Find = function(name) return inventories[name] end }
var = { VarClient = { COMBATV2_RUNECOUNT_LAW = { value = 112 } },
    VarPlayer = { MAKEX2012_RUNECOUNT_LAW = { value = 113 } } }
local text = diagnostic.read()
assert(text:find("Law: backpack=12 worn=0 combatVar=112 makeVar=113", 1, true))
assert(text:find("Blood: backpack=0 worn=0 combatVar=unavailable makeVar=unavailable", 1, true))
assert(text:find("Deathspore arrows: backpack=0 worn=20", 1, true))
inventories.INV.GetTotal = function() error("failed") end
inventories.WORN.isValid = false
assert(diagnostic.read():find("backpack=unavailable worn=unavailable", 1, true))
local messages, originalPrint = {}, print
print = function(message) messages[#messages + 1] = message end
diagnostic.update()
diagnostic.update()
assert(#messages == 1)
diagnostic.reset()
diagnostic.update()
assert(#messages == 2)
print = originalPrint
print("Rune diagnostic mock tests passed.")
