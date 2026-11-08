local saved
PersistentDB = {
    GetStructuredData = function() return saved end,
    SetStructuredData = function(_, key, value) saved = value; return true end,
}
local settings = require("warnings/settings")
local catalogue = require("supplies/catalogue")
local rules = settings.load()
assert(not rules.checkOnBankClose and rules.checkOnPreset and settings.defaults().checkOnPreset)
assert(not rules.presetChatNotifications and not settings.defaults().presetChatNotifications)
assert(rules.signOfLife and settings.defaults().signOfLife)
assert(rules.deathReclaim and settings.defaults().deathReclaim)
assert(rules.popupDuration == 4)
assert(rules.popupRows == 8)
rules.popupDuration = 12
rules.popupRows = 10
rules.checkOnBankClose, rules.checkOnPreset = true, true
rules.presetChatNotifications = true
local seen = {}
for _, rule in ipairs(rules) do seen[rule.itemId] = (seen[rule.itemId] or 0) + 1 end
for itemId, item in pairs(catalogue) do
    if item.scrimshaw then assert(seen[itemId] == nil)
    else assert(seen[itemId] == 1) end
end
assert(seen["armour-spikes"] == 1)
for _, rule in ipairs(rules) do
    assert(rule.enabled)
    if rule.itemId == 36389 then
        assert(rule.custom and rule.low == 50000 and rule.critical == 10000)
        assert(settings.effective(rules, rule).low == 50000)
    elseif rule.itemId == 22370 or rule.itemId == 22371 then
        assert(rule.custom and rule.low == 10 and rule.critical == 5)
        assert(settings.effective(rules, rule).low == 10)
    elseif catalogue[rule.itemId] and catalogue[rule.itemId].godBook then
        assert(rule.custom and rule.low == 60 and rule.critical == 30)
        assert(settings.effective(rules, rule).low == 60)
    else
        assert(not rule.custom and settings.effective(rules, rule).low == 1000)
    end
end
for _, name in ipairs({ "Magic", "Necromancy", "Ranged", "Melee", "Misc" }) do
    assert(rules.styles[name].low == 1000 and rules.styles[name].critical == 250)
end
assert(settings.style(48951) == "Misc")
assert(settings.valid({ itemId = 52494, enabled = true, low = 1440, critical = 0 }))
assert(not settings.valid({ itemId = 52494, enabled = true, low = 1441, critical = 0 }))
assert(not settings.valid({ itemId = 52494, enabled = true, low = 30, critical = 31 }))
rules.styles.Magic.low = 5000
rules[1].custom, rules[1].low, rules[1].critical = true, 70, 10
rules[2].enabled = false
assert(settings.save(rules))
assert(settings.load().presetChatNotifications, "chat notification choice persists")
saved["26295"] = { enabled = true, custom = true, low = 60, critical = 30 }
for _, rule in ipairs(settings.load()) do
    assert(rule.itemId ~= 26295, "saved scrimshaw rules must not be loaded")
end
saved.signOfLife = false
assert(not settings.load().signOfLife, "explicitly disabled sign warning remains disabled")
saved.checkOnPreset = false
assert(not settings.load().checkOnPreset, "explicitly disabled preset check remains disabled")
assert(not settings.load().presetChatNotifications, "chat notifications cannot load enabled without preset checks")
saved.checkOnPreset = nil
assert(settings.load().checkOnPreset, "missing preset setting uses the default")
saved.signOfLife = nil
assert(settings.load().signOfLife, "missing sign setting uses the default")
saved["53065"].enabled, saved["41633"].custom = false, true
saved["41633"].low, saved["41633"].critical = 77, 12
saved["36389"] = { enabled = true, custom = true, low = 12345, critical = 1234 }
saved["22370"] = { enabled = false, custom = false, low = 20, critical = 7 }
saved.styles.Magic.lowCooldown, saved.styles.Magic.criticalCooldown = 300, 60
saved.styles.Magic.warnAtZero = true
saved[tostring(rules[1].itemId)].warnAtZero = true
saved[tostring(rules[1].itemId)].lowCooldown = 300
local loaded = settings.load()
for _, rule in ipairs(loaded) do
    if rule.itemId == 53065 then assert(not rule.enabled) end
    if rule.itemId == 41633 then assert(rule.custom and rule.low == 77 and rule.critical == 12) end
    if rule.itemId == 36389 then assert(rule.custom and rule.low == 12345 and rule.critical == 1234) end
    if rule.itemId == 22370 then assert(not rule.enabled and not rule.custom and rule.low == 20 and rule.critical == 7) end
end
assert(loaded.checkOnBankClose and loaded.checkOnPreset)
assert(loaded.popupDuration == 12)
assert(loaded.popupRows == 10)
saved.popupRows = 0
assert(settings.load().popupRows == 8)
saved.popupRows = 21
assert(settings.load().popupRows == 8)
saved.popupRows = 20
assert(settings.load().popupRows == 20)
saved.popupRows = 10
loaded.popupRows = 1.5
assert(not settings.save(loaded))
loaded.popupRows = 10
saved.popupDuration = 0
assert(settings.load().popupDuration == 4)
saved.popupDuration = 3601
assert(settings.load().popupDuration == 4)
saved.popupDuration = 12
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
