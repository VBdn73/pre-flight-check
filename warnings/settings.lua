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
local key = "supplyWarnings.v1"

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
    for _, itemId in ipairs(ids) do
        local rule = saved[tostring(itemId)]
        if not settings.valid(rule) then
            rule = { enabled = itemId == 563 or itemId == 565 or itemId == 52299,
                warnAtZero = false, low = 1000, critical = 250,
                lowCooldown = 300, criticalCooldown = 60 }
        end
        rules[#rules + 1] = { itemId = itemId, enabled = rule.enabled,
            warnAtZero = rule.warnAtZero, low = rule.low, critical = rule.critical,
            lowCooldown = rule.lowCooldown, criticalCooldown = rule.criticalCooldown }
    end
    return rules
end

function settings.save(rules)
    local data = {}
    for _, rule in ipairs(rules) do
        if not settings.valid(rule) then return false end
        data[tostring(rule.itemId)] = { enabled = rule.enabled, warnAtZero = rule.warnAtZero,
            low = rule.low, critical = rule.critical, lowCooldown = rule.lowCooldown,
            criticalCooldown = rule.criticalCooldown }
    end
    local ok, result = pcall(function() return PersistentDB:SetStructuredData(key, data) end)
    return ok and result == true
end

return settings
