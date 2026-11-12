local reader = require("supplies/inventory-reader")
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
var = { VarPlayer = { INVENT_CHARGE = { value = 379197048 } }, VarClient = { COMBATV2_RUNECOUNT_LAW = { value = 123 },
    COMBATV2_RUNECOUNT_BLOOD = { value = -1 } } }

-- Read inventory, equipment, and combat rune counts.
local first = reader.read()
assert(first.backpack.available and first.backpack.counts[565] == 30)
assert(first.equipment.available and first.equipment.counts[52299] == 6872)
assert(first.runeCounts[563] == 123 and first.runeCounts[565] == nil)
assert(first.inventionCharge == 126399)
assert(first.signOfLifeCooldown == nil)
assert(first.excaliburCooldown == nil)
assert(first.powerburstCooldown == nil)
var.VarPlayer.HERB_POW_COOLDOWN = { value = 120 }
assert(reader.read().powerburstCooldown == 120)
var.VarPlayer.HERB_POW_COOLDOWN.value = 0
assert(reader.read().powerburstCooldown == 0)
var.VarPlayer.HERB_POW_COOLDOWN.value = -1
assert(reader.read().powerburstCooldown == nil)
var.VarPlayer.HERB_POW_COOLDOWN = nil
assert(reader.read().powerburstCooldown == nil)
-- The client timestamp can stay positive after an altar reset; use server state.
var.VarClient.COMBATV2_COOLDOWN_EXCALIBUR = { value = 198961 }
var.VarPlayer.COMBATV2_EXCALIBUR_SPEC = { value = 20 }
assert(reader.read().excaliburCooldown == 20)
var.VarPlayer.COMBATV2_EXCALIBUR_SPEC.value = 0
assert(reader.read().excaliburCooldown == 0)
var.VarPlayer.COMBATV2_EXCALIBUR_SPEC.value = -1
assert(reader.read().excaliburCooldown == nil)
var.VarPlayer.COMBATV2_EXCALIBUR_SPEC = nil
var.VarClient.COMBATV2_COOLDOWN_EXCALIBUR = nil
assert(reader.read().excaliburCooldown == nil)
assert(first.deathReclaim == nil)
-- Optional game variables distinguish unavailable data from zero.
var.VarPlayer.GRAVESTONE_TIMER_INV_SLOTS = { value = 0 }
var.VarPlayer.GRAVESTONE_TIMER_WORN_SLOTS = { value = 0 }
var.VarPlayer.GRAVESTONE_TIMER_OVERFLOW_SLOTS = { value = 0 }
assert(reader.read().deathReclaim == false)
var.VarPlayer.GRAVESTONE_TIMER_WORN_SLOTS.value = 11
assert(reader.read().deathReclaim == true)
var.VarPlayer.GRAVESTONE_TIMER_OVERFLOW_SLOTS = nil
assert(reader.read().deathReclaim == true)
var.VarPlayer.GRAVESTONE_TIMER_WORN_SLOTS.value = 0
assert(reader.read().deathReclaim == nil)
var.VarPlayer.GOD_BOOK_TIMELEFT = { value = 92184 }
assert(reader.read().godBookTicks == 92184)
var.VarPlayer.GOD_BOOK_TIMELEFT.value = -1
assert(reader.read().godBookTicks == nil)
var.VarPlayer.GOD_BOOK_TIMELEFT = nil
assert(reader.read().godBookTicks == nil)
var.VarPlayer.DIV_LIFE_COOLDOWN = { value = 30 }
assert(reader.read().signOfLifeCooldown == 30)
var.VarPlayer.DIV_LIFE_COOLDOWN.value = 0
assert(reader.read().signOfLifeCooldown == 0)
var.VarPlayer.DIV_LIFE_COOLDOWN.value = -1
assert(reader.read().signOfLifeCooldown == nil)
var.VarPlayer.DIV_LIFE_COOLDOWN = nil
assert(reader.read().signOfLifeCooldown == nil)
-- The decoded charge can be consumed by the monitor.
local chargeMonitor = require("warnings/monitor").new({
    { itemId = 36389, enabled = true, custom = true, low = 200000, critical = 175000 },
})
local chargeAlert = chargeMonitor.update(first)[1]
assert(chargeAlert and chargeAlert.count == 126399 and chargeAlert.level == "critical")
var.VarPlayer.INVENT_CHARGE.value = -1
assert(reader.read().inventionCharge == nil)
var.VarPlayer.INVENT_CHARGE = nil
assert(reader.read().inventionCharge == nil)
-- Snapshots do not change when the underlying inventory changes.
var.VarClient.COMBATV2_RUNECOUNT_LAW.value = 12
slots[2].count = 12
local second = reader.read()
assert(second.backpack.counts[565] == 32 and first.backpack.counts[565] == 30)
assert(second.runeCounts[563] == 12 and first.runeCounts[563] == 123)
assert(first.backpack.counts ~= second.backpack.counts)

-- Nexus contents are only attributable to a single carried nexus.
local nexusSlots = { item(55336, 11953), item(55338, 20136) }
sources[953] = { isValid = true, slotCount = 2, GetSlots = function() return nexusSlots end }
slots = { item(59360, 1), item(55338, 5), empty() }
local withNexus = reader.read()
assert(withNexus.nexus.available and withNexus.nexus.counts[55338] == 20136)
assert(withNexus.backpack.counts[55338] == 5)
nexusSlots[2].count = 20135
assert(reader.read().nexus.counts[55338] == 20135 and withNexus.nexus.counts[55338] == 20136)
sources[953].isValid = false
assert(not reader.read().nexus.available)
sources[953].isValid = true
worn = { item(56142, 1), empty() }
assert(not reader.read().nexus.available, "multiple nexuses cannot be attributed")
worn = { empty(), item(52299, 6872) }

-- Empty containers and spike harness attribution.
slots = { empty(), empty(), empty() }
assert(reader.read().backpack.available and next(reader.read().backpack.counts) == nil)
assert(reader.read().nexus.available and next(reader.read().nexus.counts) == nil)
assert(reader.read().spikeHarness.available and next(reader.read().spikeHarness.counts) == nil)
local harnessSlots = { item(57390, 1000) }
sources[974] = { isValid = true, slotCount = 1, GetSlots = function() return harnessSlots end }
slots = { item(59925, 1), item(47071, 5), empty() }
assert(reader.read().spikeHarness.counts[57390] == 1000)
harnessSlots[1].count = 999
assert(reader.read().spikeHarness.counts[57390] == 999)
worn = { item(59925, 1), empty() }
assert(not reader.read().spikeHarness.available, "multiple harnesses cannot be attributed")
slots = { item(47071, 5), empty(), empty() }
assert(reader.read().spikeHarness.counts[57390] == 999)
sources[974].isValid = false
assert(not reader.read().spikeHarness.available)
sources[974].isValid = true
-- Invalid or incomplete inventory data must not be interpreted as empty.
worn = { empty(), item(52299, 6872) }
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
