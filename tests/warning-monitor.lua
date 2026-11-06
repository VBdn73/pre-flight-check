local monitor = require("warning-monitor")
local rule = { itemId = 565, enabled = true, low = 100, critical = 25,
    lowCooldown = 300, criticalCooldown = 60, warnAtZero = false }
local instance = monitor.new({ rule })
local snapshot = { backpack = { available = true, counts = {} },
    equipment = { available = true, counts = {} } }
local function check(count, now)
    snapshot.backpack.counts[565] = count
    return instance.update(snapshot, now)
end
assert(#check(0, 0) == 0)
assert(#check(200, 1) == 0)
assert(check(99, 2)[1].level == "low")
assert(#check(50, 301) == 0)
assert(check(50, 302)[1].level == "low")
assert(check(24, 303)[1].level == "critical")
assert(#check(24, 362) == 0)
assert(check(24, 363)[1].level == "critical")
assert(#check(0, 364) == 0)
assert(check(24, 365)[1].level == "critical")
snapshot.equipment.available = false
assert(#check(10, 500) == 0)
snapshot.equipment.available = true
assert(check(10, 500)[1].level == "critical")
rule.enabled = false
assert(#check(10, 501) == 0)
rule.enabled, rule.warnAtZero = true, true
assert(check(0, 502)[1].count == 0)
instance.reset()
assert(check(0, 503)[1].level == "critical")
print("Warning monitor tests passed.")
