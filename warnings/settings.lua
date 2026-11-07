-- Persistent settings for the initial set of exact-item warnings.
local settings = {}
local ids = { 563, 565, 52299 }
local catalogue = require("supply-catalogue")
local spikes = require("armour-spikes")
local additional = {}
local ammunition = {}
for itemId, item in pairs(catalogue) do
    if (item.combatVar and itemId ~= 563 and itemId ~= 565) or item.nexus then
        additional[#additional + 1] = itemId
    elseif item.category == "ammunition" and itemId ~= 52299 then
        ammunition[#ammunition + 1] = itemId
    elseif item.category == "misc" then
        additional[#additional + 1] = itemId
    end
end
table.sort(additional)
for _, itemId in ipairs(additional) do ids[#ids + 1] = itemId end
-- Put widely used ammunition first within each section; sort the rest by name.
local priority = { [53055] = 1, [53065] = 2, [53060] = 3, [53050] = 4, [53043] = 5,
    [52289] = 1, [47501] = 2, [31737] = 3,
    [41633] = 1, [41629] = 2, [41630] = 3, [41632] = 4,
    [28465] = 1, [42748] = 2, [24336] = 3, [35989] = 4,
    [31881] = 1, [9242] = 2, [9243] = 3 }
table.sort(ammunition, function(a, b)
    local pa, pb = priority[a] or 100, priority[b] or 100
    if pa ~= pb then return pa < pb end
    return catalogue[a].name < catalogue[b].name
end)
for _, itemId in ipairs(ammunition) do ids[#ids + 1] = itemId end
ids[#ids + 1] = spikes.ruleId
local key = "supplyWarnings.v2"
local styles = { "Magic", "Necromancy", "Ranged", "Melee", "Misc" }

local function defaults()
    return { enabled = true, low = 1000, critical = 250 }
end

function settings.style(itemId)
    if itemId == spikes.ruleId then return "Melee" end
    local item = catalogue[itemId]
    if item.category == "rune" then return "Magic" end
    if item.category == "necromancy" then return "Necromancy" end
    if item.category == "misc" then return "Misc" end
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
        and validInteger(rule.low, 1, 2147483647)
        and validInteger(rule.critical, 1, rule.low)
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
        rules.styles[style] = settings.valid(value) and
            { enabled = true, low = value.low, critical = value.critical } or defaults()
    end
    for _, itemId in ipairs(ids) do
        local rule = saved[tostring(itemId)]
        if not settings.valid(rule) then
            rule = defaults()
        end
        rules[#rules + 1] = { itemId = itemId, enabled = rule.enabled,
            low = rule.low, critical = rule.critical,
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
        data.styles[style] = { enabled = true, low = value.low, critical = value.critical }
    end
    for _, rule in ipairs(rules) do
        if not settings.valid(rule) then return false end
        data[tostring(rule.itemId)] = { enabled = rule.enabled,
            low = rule.low, critical = rule.critical, custom = rule.custom == true }
    end
    local ok, result = pcall(function() return PersistentDB:SetStructuredData(key, data) end)
    return ok and result == true
end

return settings
