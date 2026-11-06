-- Read independent, fresh snapshots; never retain an Inventory proxy across calls.
local reader = {}
local catalogue = require("supply-catalogue")

local function integer(value, minimum)
    return type(value) == "number" and value >= minimum
        and value < math.huge and value % 1 == 0
end

local function readSource(name)
    local ok, result = pcall(function()
        if not Inventory or not config or not config.Inv or not config.Inv[name] then
            return nil
        end
        local inventory = Inventory.Find(config.Inv[name])
        if not inventory or not inventory.isValid then return nil end
        local size = inventory.slotCount
        local slots = inventory:GetSlots()
        if not integer(size, 0) or type(slots) ~= "table" then return nil end

        local counts = {}
        local seen = 0
        for index, slot in pairs(slots) do
            if not integer(index, 1) or index > size or not slot then return nil end
            seen = seen + 1
            local obj = slot.obj
            if not obj then return nil end
            local id, count = obj.id, slot.count
            if id == -1 and count == 0 then
                -- Observed empty-slot representation in the client.
            elseif integer(id, 0) and integer(count, 1) then
                local total = (counts[id] or 0) + count
                if not integer(total, 1) then return nil end
                counts[id] = total
            else
                return nil
            end
        end
        if seen ~= size then return nil end
        return counts
    end)
    if not ok or not result then return { available = false } end
    return { available = true, counts = result }
end

function reader.read()
    local runes = {}
    for itemId, item in pairs(catalogue) do
        if item.combatVar then
            local ok, count = pcall(function() return var.VarClient[item.combatVar].value end)
            if ok and integer(count, 0) then runes[itemId] = count end
        end
    end
    return { backpack = readSource("INV"), equipment = readSource("WORN"), runeCounts = runes }
end

return reader
