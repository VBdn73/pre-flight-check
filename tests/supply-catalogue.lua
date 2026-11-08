local catalogue = require("supplies/catalogue")
assert(catalogue[563].name == "Law rune" and catalogue[563].category == "rune")
assert(catalogue[565].name == "Blood rune" and catalogue[565].category == "rune")
assert(catalogue[52299].name == "Deathspore arrows" and catalogue[52299].category == "ammunition")
assert(catalogue[28465].name == "Ascension bolts" and catalogue[53065].name == "Bik arrow")
assert(catalogue[41633].group == "Enchanted Bakriminel Bolts")
assert(catalogue[41684].group == "Bakriminel Bolts")
for itemId, name in pairs({ [48951] = "Vulnerability bomb", [48954] = "Poison bomb", [48957] = "Sticky bomb" }) do
    local item = catalogue[itemId]
    assert(item.name == name and item.category == "misc" and item.group == "Bombs")
end
for itemId, name in pairs({ [22370] = "Dreadnip", [22371] = "Dominion mine" }) do
    local item = catalogue[itemId]
    assert(item.name == name and item.category == "misc" and item.group == "Other")
end
for itemId, name in pairs({ [10033] = "Chinchompa", [10034] = "Red chinchompa",
    [60791] = "Black chinchompa", [36391] = "Mechanised chinchompa" }) do
    local item = catalogue[itemId]
    assert(item.name == name and item.category == "ammunition" and item.group == "Chinchompas")
end
local count = 0
for _, item in pairs(catalogue) do
    if item.combatVar then count = count + 1 end
end
assert(count == 22 and catalogue[58450].combatVar == "COMBATV2_RUNECOUNT_TIME")
print("Supply catalogue tests passed.")
