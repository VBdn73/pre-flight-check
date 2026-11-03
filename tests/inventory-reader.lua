local reader = require("inventory-reader")
local empty = function() return { obj = { id = -1 }, count = 0 } end
local item = function(id, count) return { obj = { id = id }, count = count } end
local slots = { empty(), item(565, 10), item(565, 20) }
local worn = { empty(), item(52299, 6872) }
local sources = {
    INV = { isValid = true, slotCount = 3, GetSlots = function() return slots end },
    WORN = { isValid = true, slotCount = 2, GetSlots = function() return worn end },
}
config = { Inv = { INV = "INV", WORN = "WORN" } }
Inventory = { Find = function(name) return sources[name] end }

local first = reader.read()
assert(first.backpack.available and first.backpack.counts[565] == 30)
assert(first.equipment.available and first.equipment.counts[52299] == 6872)
slots[2].count = 12
local second = reader.read()
assert(second.backpack.counts[565] == 32 and first.backpack.counts[565] == 30)
assert(first.backpack.counts ~= second.backpack.counts)

slots = { empty(), empty(), empty() }
assert(reader.read().backpack.available and next(reader.read().backpack.counts) == nil)
slots = { empty(), item(565, 1) }
assert(not reader.read().backpack.available) -- missing slot
slots = { empty(), item(565, -1), empty() }
assert(not reader.read().backpack.available)
slots = { empty(), item(565, 1.5), empty() }
assert(not reader.read().backpack.available)
slots = { empty(), { count = 0 }, empty() }
assert(not reader.read().backpack.available)
slots = { empty(), item(-1, 1), empty() }
assert(not reader.read().backpack.available)
slots = { empty(), item(565, 1), empty(), empty() }
assert(not reader.read().backpack.available)
sources.INV.GetSlots = function() return nil end
assert(not reader.read().backpack.available)
sources.INV.GetSlots = function() error("read failed") end
assert(not reader.read().backpack.available and reader.read().equipment.available)
sources.WORN.isValid = false
assert(not reader.read().equipment.available)
config.Inv.WORN = nil
assert(not reader.read().equipment.available)
Inventory.Find = function() return nil end
assert(not reader.read().backpack.available)
print("Inventory reader mock tests passed.")
