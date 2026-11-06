local catalogue = require("supply-catalogue")
assert(catalogue[563].name == "Law rune" and catalogue[563].category == "rune")
assert(catalogue[565].name == "Blood rune" and catalogue[565].category == "rune")
assert(catalogue[52299].name == "Deathspore arrows" and catalogue[52299].category == "ammunition")
assert(catalogue[28465] == nil and catalogue[53065] == nil)
local count = 0
for _, item in pairs(catalogue) do
    if item.combatVar then count = count + 1 end
end
assert(count == 22 and catalogue[58450].combatVar == "COMBATV2_RUNECOUNT_TIME")
print("Supply catalogue tests passed.")
