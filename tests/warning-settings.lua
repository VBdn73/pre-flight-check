local saved
PersistentDB = {
    GetStructuredData = function() return saved end,
    SetStructuredData = function(_, key, value) saved = value; return true end,
}
local settings = require("warnings/settings")
local rules = settings.load()
assert(#rules == 29 and not rules[1].warnAtZero)
for _, rule in ipairs(rules) do assert(rule.low == 1000 and rule.critical == 250) end
assert(rules[29].itemId == "armour-spikes" and not rules[29].enabled
    and rules[29].low == 1000 and rules[29].critical == 250)
assert(not rules[4].enabled and rules[1].enabled)
rules[1].enabled = false
rules[2].low, rules[2].critical = 70, 10
rules[29].low, rules[29].critical = 5000, 1000
assert(settings.save(rules))
local loaded = settings.load()
assert(not loaded[1].enabled and loaded[2].low == 70 and loaded[2].critical == 10)
assert(loaded[29].low == 5000 and loaded[29].critical == 1000)
loaded[1].critical = 1001
assert(not settings.save(loaded))
saved["563"].critical = -1
assert(settings.load()[1].critical == 250)
PersistentDB.SetStructuredData = function() return false end
assert(not settings.save(rules))
print("Warning settings tests passed.")
