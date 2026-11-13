local vitals = require("supplies/vitals")
Player = {
    IsAvailable = function() return true end,
    GetLevelCapped = function(skill)
        assert(skill == 5 or skill == 23)
        return 99
    end,
    GetLevelGameplay = function(skill) assert(skill == 23); return 39 end,
}
SkillType = nil -- The resource reader must not depend on a global enum table.
var = { VarPlayer = {
    LIFEPOINTS = { value = 3900 }, MAXLIFEPOINTS = { value = 10000 },
    SA_ENERGY = { value = 399 }, PRAYER_POINTS = { value = 3900 },
    LORE_POINTS = { value = 3800 }, LORE_SPELL_POINTS = { value = 29 },
} }
local values = vitals.read()
assert(values.health == 39 and math.abs(values.adrenaline - 39.9) < 0.0001)
assert(math.abs(values.prayer - 390 / 990 * 100) < 0.0001)
assert(math.abs(values.summoning - 3800 / 9900 * 100) < 0.0001)
assert(math.abs(values.familiarSpecial - 29 / 60 * 100) < 0.0001)
local settings = require("warnings/settings")
local rules = settings.defaults()
assert(rules.familiarSpecial == false)
rules.familiarSpecial = true
local monitor = require("warnings/monitor").new(rules)
local snapshot = { vitals = values, backpack = { available = false }, equipment = { available = false } }
local alerts = monitor.update(snapshot)
assert(#alerts == 5)
for i, vital in ipairs(vitals) do
    assert(rules[vital.key] and rules[vital.key .. "Threshold"] == vital.threshold)
    assert(alerts[i].icon == vital.icon)
    assert(require("warnings/popup-icons").source(alerts[i]) == vital.icon)
    values[vital.key] = vital.threshold
end
assert(#monitor.update(snapshot) == 0)
var.VarPlayer.PRAYER_POINTS.value = 4413
snapshot.vitals = vitals.read()
rules.health, rules.adrenaline, rules.summoning = false, false, false
rules.familiarSpecial = false
alerts = monitor.update(snapshot)
assert(#alerts == 1 and alerts[1].name == "Prayer points")
assert(alerts[1].message == "Prayer points: 44% remaining")
snapshot.vitals = values
rules.health, rules.adrenaline, rules.summoning = true, true, true
rules.familiarSpecial = true
values.health = 0
assert(#monitor.update(snapshot) == 1)
rules.health = false
assert(#monitor.update(snapshot) == 0)
rules.health = true
rules.healthThreshold = 0
assert(#monitor.update(snapshot) == 0)
assert(settings.validPercentage(100) and not settings.validPercentage(101))
assert(settings.validPercentage(150, "adrenalineThreshold"))
assert(not settings.validPercentage(151, "adrenalineThreshold"))
assert(not settings.validPercentage(101, "healthThreshold"))
assert(not settings.validPercentage(101, "prayerThreshold"))
assert(not settings.validPercentage(101, "summoningThreshold"))
assert(not settings.validPercentage(-1) and not settings.validPercentage(0 / 0))
Player.IsAvailable = function() return false end
assert(next(vitals.read()) == nil)
Player.IsAvailable = function() return true end
var.VarPlayer.MAXLIFEPOINTS.value = 0
var.VarPlayer.SA_ENERGY = nil
var.VarPlayer.LORE_POINTS = nil
values = vitals.read()
assert(values.health == nil and values.adrenaline == nil and values.summoning == nil)
assert(values.prayer ~= nil)
print("Vital percentage tests passed.")
