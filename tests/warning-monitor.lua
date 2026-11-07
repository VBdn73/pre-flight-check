local monitor = require("warnings/monitor")
local rule = { itemId = 565, enabled = true, low = 100, critical = 25, warnAtZero = false }
local instance = monitor.new({ rule })
local snapshot = { backpack = { available = true, counts = {} },
    equipment = { available = true, counts = {} }, runeCounts = {} }
local function check(count, now)
    snapshot.runeCounts[565] = count
    return instance.update(snapshot, now)
end
assert(#check(0, 0) == 0)
assert(#check(200, 1) == 0)
assert(check(99, 2)[1].level == "low")
assert(#check(50, 301) == 1, "each check reports low supplies")
assert(check(50, 302)[1].level == "low")
assert(check(24, 303)[1].level == "critical")
assert(#check(24, 362) == 1)
assert(check(24, 363)[1].level == "critical")
assert(#check(0, 364) == 0)
assert(check(24, 365)[1].level == "critical")
snapshot.runeCounts[565] = nil
snapshot.runeCounts = nil
assert(#instance.update(snapshot, 500) == 0)
snapshot.runeCounts = {}
assert(check(10, 500)[1].level == "critical")
rule.enabled = false
assert(#check(10, 501) == 0)
rule.enabled, rule.warnAtZero = true, true
assert(#check(0, 502) == 0, "legacy zero setting must not enable zero warnings")
snapshot.backpack.counts[565] = 10000
assert(check(10, 504)[1].count == 10, "combat count must not be added to loose runes")
snapshot.runeCounts[565] = nil
assert(#instance.update(snapshot, 505) == 0, "missing combat count must not be treated as zero")
local necro = monitor.new({ { itemId = 55338, enabled = true, low = 100, critical = 25,
    warnAtZero = true } })
snapshot.backpack.counts[55338] = 5
snapshot.nexus = { available = true, counts = { [55338] = 30 } }
assert(necro.update(snapshot, 1)[1].count == 35)
snapshot.nexus.available = false
assert(#necro.update(snapshot, 2) == 0)
snapshot.nexus = { available = true, counts = {} }
assert(necro.update(snapshot, 3)[1].count == 5)
local spikes = monitor.new({ { itemId = "armour-spikes", enabled = true, low = 1000, critical = 250,
    warnAtZero = true } })
snapshot.backpack.counts = { [47071] = 100, [47872] = 20, [52938] = 10 }
snapshot.equipment.counts = { [52939] = 5, [57389] = 4 }
snapshot.spikeHarness = { available = true, counts = { [57390] = 100 } }
local alert = spikes.update(snapshot, 1)[1]
assert(alert.name == "Armour spikes" and alert.count == 239 and alert.level == "critical")
snapshot.spikeHarness.counts[57390] = 111
assert(spikes.update(snapshot, 2)[1].level == "low", "250 is not below critical")
snapshot.spikeHarness.counts[57390] = 861
assert(#spikes.update(snapshot, 3) == 0, "1000 is not below low")
snapshot.spikeHarness.available = false
assert(#spikes.update(snapshot, 100) == 0)
snapshot.spikeHarness = { available = true, counts = {} }
snapshot.backpack.available = false
assert(#spikes.update(snapshot, 200) == 0)
snapshot.backpack.available = true
snapshot.backpack.counts, snapshot.equipment.counts = {}, {}
assert(#spikes.update(snapshot, 201) == 0)
local sharedRules = { styles = { Magic = { enabled = true, low = 5000, critical = 1000,
    warnAtZero = true } },
    { itemId = 554, enabled = true, custom = false, low = 100, critical = 25,
        warnAtZero = false } }
local sharedMonitor = monitor.new(sharedRules)
snapshot.runeCounts[554] = 2000
assert(sharedMonitor.update(snapshot, 1)[1].level == "low")
sharedRules[1].custom = true
assert(#sharedMonitor.update(snapshot, 2) == 0)
snapshot.runeCounts[554] = 0
assert(#sharedMonitor.update(snapshot, 3) == 0)
sharedRules[1].custom = false
assert(#sharedMonitor.update(snapshot, 4) == 0)
sharedRules[1].enabled = false
assert(#sharedMonitor.update(snapshot, 5) == 0)
local ammo = monitor.new({ { itemId = 53065, enabled = true, low = 100, critical = 25 },
    { itemId = 41633, enabled = true, low = 100, critical = 25 } })
snapshot.backpack.counts = { [53065] = 10, [41633] = 30, [41684] = 500 }
snapshot.equipment.counts = { [53065] = 5, [41633] = 20 }
local alerts = ammo.update(snapshot, 1)
assert(#alerts == 2 and alerts[1].count == 15 and alerts[2].count == 50)
snapshot.equipment.available = false
assert(#ammo.update(snapshot, 2) == 0)
local bombs = monitor.new({ { itemId = 48951, enabled = true, low = 100, critical = 25 } })
snapshot.equipment.available = true
snapshot.backpack.counts = { [48951] = 10 }
snapshot.equipment.counts = {}
assert(bombs.update(snapshot)[1].count == 10 and bombs.update(snapshot)[1].level == "critical")
snapshot.backpack.available = false
assert(#bombs.update(snapshot) == 0)
local charge = monitor.new({ { itemId = 36389, enabled = true, low = 1000, critical = 250 } })
snapshot.inventionCharge = 249
assert(charge.update(snapshot)[1].count == 249 and charge.update(snapshot)[1].level == "critical")
snapshot.inventionCharge = 250
assert(charge.update(snapshot)[1].level == "low")
snapshot.inventionCharge = 1000
assert(#charge.update(snapshot) == 0)
snapshot.inventionCharge = nil
assert(#charge.update(snapshot) == 0)
local signRules = { signOfLife = true }
local deathRules = { deathReclaim = true }
local deathMonitor = require("warnings/monitor").new(deathRules)
assert(#deathMonitor.update({ deathReclaim = false }) == 0)
assert(#deathMonitor.update({}) == 0)
assert(deathMonitor.update({ deathReclaim = true })[1].level == "critical")
assert(#deathMonitor.update({ deathReclaim = true }) == 1, "every check repeats the warning")
deathRules.deathReclaim = false
assert(#deathMonitor.update({ deathReclaim = true }) == 0)
local sign = monitor.new(signRules)
snapshot.signOfLifeCooldown = 30
assert(sign.update(snapshot)[1].message == "Sign of life: 30 min")
snapshot.signOfLifeCooldown = 1
assert(sign.update(snapshot)[1].message == "Sign of life: 1 min")
snapshot.signOfLifeCooldown = 0
assert(#sign.update(snapshot) == 0)
snapshot.signOfLifeCooldown = nil
assert(#sign.update(snapshot) == 0)
snapshot.signOfLifeCooldown = 30
signRules.signOfLife = false
assert(#sign.update(snapshot) == 0)
local ful = monitor.new({ { itemId = 52494, enabled = true, low = 60, critical = 30 } })
snapshot.equipment = { available = true, counts = { [52494] = 1 } }
snapshot.godBookTicks = 6000
assert(#ful.update(snapshot) == 0)
snapshot.godBookTicks = 5999
assert(ful.update(snapshot)[1].level == "low")
snapshot.godBookTicks = 3000
assert(ful.update(snapshot)[1].level == "low")
snapshot.godBookTicks = 2999
assert(ful.update(snapshot)[1].level == "critical")
snapshot.godBookTicks = 0
assert(ful.update(snapshot)[1].message == "Scripture of Ful: 0:00:00 remaining")
snapshot.equipment.counts = {}
assert(#ful.update(snapshot) == 0)
snapshot.equipment.available = false
assert(#ful.update(snapshot) == 0)
snapshot.equipment = { available = true, counts = { [52494] = 1 } }
snapshot.godBookTicks = nil
assert(#ful.update(snapshot) == 0)
local books = { 3840, 3842, 3844, 19613, 19615, 19617, 22420, 22421, 22422,
    22423, 22424, 22425, 42787, 51814, 52117, 52347, 52494, 57126, 57526, 61425 }
local catalogue = require("supply-catalogue")
for _, id in ipairs(books) do
    local book = monitor.new({ { itemId = id, enabled = true, low = 60, critical = 30 } })
    snapshot.equipment.counts = { [id] = 1 }
    snapshot.godBookTicks = 2999
    local found = book.update(snapshot)
    assert(#found == 1 and found[1].itemId == id and found[1].level == "critical")
    assert(catalogue[id].godBook and catalogue[id].group == "God Books")
    snapshot.equipment.counts = {}
    assert(#book.update(snapshot) == 0)
end
print("Warning monitor tests passed.")
