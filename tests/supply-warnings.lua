local warnings = require("warnings/evaluate")
local snapshot = {
    backpack = { available = true, counts = { [563] = 99, [565] = 100, [52299] = 30 } },
    equipment = { available = true, counts = { [52299] = 70 } },
}
local low = warnings.evaluate(snapshot)
assert(#low == 1 and low[1].itemId == 563 and low[1].count == 99)
snapshot.equipment.counts[52299] = 69
low = warnings.evaluate(snapshot)
assert(#low == 2 and low[2].itemId == 52299 and low[2].count == 99)
snapshot.backpack.counts = {}
snapshot.equipment.counts = {}
assert(#warnings.evaluate(snapshot) == 3, "known empty inventories count as zero")
snapshot.equipment = { available = false }
assert(warnings.evaluate(snapshot) == nil, "unavailable is not zero")
snapshot.equipment = { available = true, counts = {} }
snapshot.backpack = { available = false }
assert(warnings.evaluate(snapshot) == nil)
snapshot.backpack = { available = true, counts = { [563] = 7 } }
low = warnings.evaluate(snapshot, { { itemId = 563, threshold = 8 } })
assert(#low == 1 and low[1].count == 7 and low[1].threshold == 8)
print("Supply warning decision tests passed.")
