local saved
PersistentDB = {
    GetStructuredData = function() return saved end,
    SetStructuredData = function(_, key, value) saved = value; return true end,
}
local settings = require("warnings/settings")
local rules = settings.load()
assert(not rules.checkOnBankClose and not rules.checkOnPreset)
rules.checkOnBankClose, rules.checkOnPreset = true, true
local seen = {}
for _, rule in ipairs(rules) do seen[rule.itemId] = (seen[rule.itemId] or 0) + 1 end
for itemId in pairs(require("supply-catalogue")) do assert(seen[itemId] == 1) end
assert(seen["armour-spikes"] == 1)
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
saved["53065"].enabled, saved["41633"].custom = false, true
saved["41633"].low, saved["41633"].critical = 77, 12
saved.styles.Magic.lowCooldown, saved.styles.Magic.criticalCooldown = 300, 60
saved.styles.Magic.warnAtZero = true
saved[tostring(rules[1].itemId)].warnAtZero = true
saved[tostring(rules[1].itemId)].lowCooldown = 300
local loaded = settings.load()
for _, rule in ipairs(loaded) do
    if rule.itemId == 53065 then assert(not rule.enabled) end
    if rule.itemId == 41633 then assert(rule.custom and rule.low == 77 and rule.critical == 12) end
end
assert(loaded.checkOnBankClose and loaded.checkOnPreset)
assert(loaded.styles.Magic.warnAtZero == nil and loaded[1].warnAtZero == nil)
assert(settings.effective(loaded, loaded[1]).low == 70)
assert(settings.effective(loaded, loaded[2]).low == 5000 and not loaded[2].enabled)
assert(settings.save(loaded))
assert(saved.styles.Magic.lowCooldown == nil and saved[tostring(rules[1].itemId)].lowCooldown == nil)
assert(saved.styles.Magic.warnAtZero == nil and saved[tostring(rules[1].itemId)].warnAtZero == nil)
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
