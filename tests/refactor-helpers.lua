local position = require("warnings/overlay-position")
local presetAlerts = require("bank/preset-alerts")
local counts = require("supplies/count")

assert(position.valid({ x = 0, y = -10 }))
assert(not position.valid({ x = math.huge, y = 0 }))
assert(not position.valid({ x = 0 / 0, y = 0 }))
assert(not position.valid({ x = "1", y = 0 }))
local x, y = position.clamp(90, -5, { width = 100, height = 80 }, 30, 20)
assert(x == 70 and y == 0)
x, y = position.clamp(90, 90, { width = 10, height = 10 }, 30, 20)
assert(x == 0 and y == 0)
x, y = position.clamp(90, 90, {}, 30, 20)
assert(x == 90 and y == 90)

local tracked = { { itemId = 1, name = " Air rune ", count = 10 } }
local duplicate = { name = "air rune", status = "Missing" }
local charge = { name = "AIR RUNE", status = "5%" }
local other = { name = "Fire rune", status = "Missing" }
assert(presetAlerts.merge(tracked, { duplicate, charge, other }) == tracked)
assert(#tracked == 3 and tracked[2] == charge and tracked[3] == other)

local snapshot = {
    backpack = { available = true, counts = { [1] = 3 } },
    equipment = { available = true, counts = { [1] = 2 } },
    nexus = { available = true, counts = { [1] = 4 } },
}
assert(counts.available(snapshot))
assert(counts.read(snapshot, 1, {}) == 5)
assert(counts.read(snapshot, 1, { nexus = true }) == 9)
snapshot.nexus.available = false
assert(counts.read(snapshot, 1, { nexus = true }) == nil)
snapshot.backpack.available = false
assert(not counts.available(snapshot))
assert(counts.read(snapshot, 1, {}) == nil)
assert(counts.read(snapshot, 1, { inventionCharge = true }) == nil)
print("Refactored helper tests passed.")
