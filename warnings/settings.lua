-- Persistent settings for the initial set of exact-item warnings.
local settings = {}
local ids = { 563, 565, 52299 }
local catalogue = require("supply-catalogue")
local spikes = require("armour-spikes")
local additional = {}
for itemId, item in pairs(catalogue) do
    if (item.combatVar and itemId ~= 563 and itemId ~= 565) or item.nexus then
        additional[#additional + 1] = itemId
    end
end
table.sort(additional)
for _, itemId in ipairs(additional) do ids[#ids + 1] = itemId end
ids[#ids + 1] = spikes.ruleId
local key = "supplyWarnings.v2"
local styles = { "Magic", "Necromancy", "Ranged", "Melee" }

local function defaults()
    return { enabled = true, warnAtZero = false, low = 1000, critical = 250,
        lowCooldown = 300, criticalCooldown = 60 }
end

function settings.style(itemId)
    if itemId == spikes.ruleId then return "Melee" end
    local item = catalogue[itemId]
    if item.category == "rune" then return "Magic" end
    if item.category == "necromancy" then return "Necromancy" end
    return "Ranged"
end

function settings.effective(rules, rule)
    if not rule.custom and rules.styles then
        return rules.styles[settings.style(rule.itemId)]
    end
    return rule
end

local function validInteger(n, min, max)
    return type(n) == "number" and n == n and n >= min and n <= max and n % 1 == 0
end

function settings.valid(rule)
    return type(rule) == "table" and type(rule.enabled) == "boolean"
        and type(rule.warnAtZero) == "boolean"
        and validInteger(rule.low, 1, 2147483647)
        and validInteger(rule.critical, 1, rule.low)
        and validInteger(rule.lowCooldown, 1, 86400)
        and validInteger(rule.criticalCooldown, 1, 86400)
end

function settings.load()
    local ok, saved = pcall(function() return PersistentDB:GetStructuredData(key) end)
    if not ok or type(saved) ~= "table" then saved = {} end
    local rules = {}
    rules.checkOnPreset = saved.checkOnPreset == true
    rules.checkOnBankClose = saved.checkOnBankClose == true
    rules.styles = {}
    for _, style in ipairs(styles) do
        local value = type(saved.styles) == "table" and saved.styles[style]
        rules.styles[style] = settings.valid(value) and value or defaults()
    end
    for _, itemId in ipairs(ids) do
        local rule = saved[tostring(itemId)]
        if not settings.valid(rule) then
            rule = defaults()
        end
        rules[#rules + 1] = { itemId = itemId, enabled = rule.enabled,
            warnAtZero = rule.warnAtZero, low = rule.low, critical = rule.critical,
            lowCooldown = rule.lowCooldown, criticalCooldown = rule.criticalCooldown,
            custom = rule.custom == true }
    end
    return rules
end

function settings.save(rules)
    local data = { styles = {}, checkOnPreset = rules.checkOnPreset == true,
        checkOnBankClose = rules.checkOnBankClose == true }
    for _, style in ipairs(styles) do
        if not rules.styles or not settings.valid(rules.styles[style]) then return false end
        local value = rules.styles[style]
        data.styles[style] = { enabled = true, warnAtZero = value.warnAtZero,
            low = value.low, critical = value.critical, lowCooldown = value.lowCooldown,
            criticalCooldown = value.criticalCooldown }
    end
    for _, rule in ipairs(rules) do
        if not settings.valid(rule) then return false end
        data[tostring(rule.itemId)] = { enabled = rule.enabled, warnAtZero = rule.warnAtZero,
            low = rule.low, critical = rule.critical, lowCooldown = rule.lowCooldown,
            criticalCooldown = rule.criticalCooldown, custom = rule.custom == true }
    end
    local ok, result = pcall(function() return PersistentDB:SetStructuredData(key, data) end)
    return ok and result == true
end

return settings
