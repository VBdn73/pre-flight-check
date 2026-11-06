local saved
PersistentDB = {
    GetStructuredData = function() return saved end,
    SetStructuredData = function(_, key, value) saved = value; return true end,
}
local settings = require("warnings/settings")
local rules = settings.load()
assert(#rules == 3 and rules[1].low == 100 and not rules[1].warnAtZero)
rules[1].enabled = false
rules[2].low, rules[2].critical = 70, 10
assert(settings.save(rules))
local loaded = settings.load()
assert(not loaded[1].enabled and loaded[2].low == 70 and loaded[2].critical == 10)
loaded[1].critical = 101
assert(not settings.save(loaded))
saved["563"].critical = -1
assert(settings.load()[1].critical == 25)
PersistentDB.SetStructuredData = function() return false end
assert(not settings.save(rules))
print("Warning settings tests passed.")
