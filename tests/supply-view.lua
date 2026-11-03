local view = require("supply-view")
local text = view.format({ backpack = { available = true, counts = { [563] = 67 } },
    equipment = { available = true, counts = { [563] = 5, [52299] = 42 } } })
assert(text:find("Backpack: 67 | Equipment: 5<br>Total: 72", 1, true))
assert(text:find("Backpack: 0 | Equipment: 42<br>Total: 42", 1, true))
assert(text:find("Pouches, quivers and other containers excluded.", 1, true))
text = view.format({ backpack = { available = true, counts = {} }, equipment = { available = false } })
assert(text:find("Backpack: 0 | Equipment: unavailable<br>Total: unavailable", 1, true))
print("Supply view tests passed.")
