local saved
PersistentDB = {
    GetStructuredData = function() return saved end,
    SetStructuredData = function(_, key, value) saved = value; return true end,
}
local settings = require("warnings/settings")
local rules = settings.load()
assert(#rules == 29)
for _, rule in ipairs(rules) do
    assert(rule.enabled and not rule.custom)
    assert(settings.effective(rules, rule).low == 1000)
end
for _, name in ipairs({ "Magic", "Necromancy", "Ranged", "Melee" }) do
    assert(rules.styles[name].low == 1000 and rules.styles[name].critical == 250)
end
rules.styles.Magic.low = 5000
rules[1].custom, rules[1].low, rules[1].critical = true, 70, 10
rules[2].enabled = false
assert(settings.save(rules))
local loaded = settings.load()
assert(settings.effective(loaded, loaded[1]).low == 70)
assert(settings.effective(loaded, loaded[2]).low == 5000 and not loaded[2].enabled)
loaded[1].custom = false
assert(settings.effective(loaded, loaded[1]).low == 5000 and loaded[1].low == 70)
loaded[1].custom = true
assert(settings.effective(loaded, loaded[1]).low == 70)
loaded.styles.Magic.critical = 5001
assert(not settings.save(loaded))
saved.styles.Magic.critical = -1
assert(settings.load().styles.Magic.critical == 250)
PersistentDB.SetStructuredData = function() return false end
assert(not settings.save(rules))
print("Warning settings tests passed.")
