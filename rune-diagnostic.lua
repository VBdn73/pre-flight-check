-- Temporary diagnostic only: none of these readings are used for warnings.
local diagnostic = {}
local previous
local items = {
    { name = "Law", id = 563, variable = "COMBATV2_RUNECOUNT_LAW", make = "MAKEX2012_RUNECOUNT_LAW" },
    { name = "Blood", id = 565, variable = "COMBATV2_RUNECOUNT_BLOOD", make = "MAKEX2012_RUNECOUNT_BLOOD" },
    { name = "Deathspore arrows", id = 52299 },
}

local function value(read)
    local ok, result = pcall(read)
    if ok and type(result) == "number" and result >= 0 and result < math.huge and result % 1 == 0 then
        return tostring(result)
    end
    return "unavailable"
end

local function total(source, itemId)
    return value(function()
        local inventory = Inventory.Find(config.Inv[source])
        if not inventory or not inventory.isValid then return nil end
        return inventory:GetTotal(itemId)
    end)
end

local function variable(domain, name)
    return value(function() return var[domain][name].value end)
end

function diagnostic.read()
    local lines = {}
    for _, item in ipairs(items) do
        local line = item.name .. ": backpack=" .. total("INV", item.id)
            .. " worn=" .. total("WORN", item.id)
        if item.variable then
            line = line .. " combatVar=" .. variable("VarClient", item.variable)
                .. " makeVar=" .. variable("VarPlayer", item.make)
        end
        lines[#lines + 1] = line
    end
    return table.concat(lines, "\n")
end

function diagnostic.update()
    local result = diagnostic.read()
    if result ~= previous then
        print("[supply-check] Supply diagnostic (not used for warnings):\n" .. result)
        previous = result
    end
end

function diagnostic.reset()
    previous = nil
end

return diagnostic
