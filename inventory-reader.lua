-- Read independent, fresh snapshots; never retain an Inventory proxy across calls.
local reader = {}
local catalogue = require("supply-catalogue")
local spikes = require("armour-spikes")

local function integer(value, minimum)
    return type(value) == "number" and value >= minimum
        and value < math.huge and value % 1 == 0
end

local function readSource(name)
    local ok, result = pcall(function()
        if not Inventory then return nil end
        local binding = name
        if type(name) == "string" then
            if not config or not config.Inv or not config.Inv[name] then return nil end
            binding = config.Inv[name]
        end
        if not binding then
            return nil
        end
        local inventory = Inventory.Find(binding)
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
    local charge
    local signOfLifeCooldown
    local cooldownOk, cooldown = pcall(function() return var.VarPlayer.DIV_LIFE_COOLDOWN.value end)
    if cooldownOk and integer(cooldown, 0) then signOfLifeCooldown = cooldown end
    local ok, raw = pcall(function() return var.VarPlayer.INVENT_CHARGE.value end)
    if ok and integer(raw, 0) then charge = math.floor(raw / 3000) end
    for itemId, item in pairs(catalogue) do
        if item.combatVar then
            local ok, count = pcall(function() return var.VarClient[item.combatVar].value end)
            if ok and integer(count, 0) then runes[itemId] = count end
        end
    end
    local backpack, equipment = readSource("INV"), readSource("WORN")
    local nexus, spikeHarness = { available = false }, { available = false }
    if backpack.available and equipment.available then
        local count = 0
        -- Include uncharged variants conservatively; their contents are not assumed empty.
        for _, id in ipairs({ 56141, 56142, 56143, 59358, 59359, 59360 }) do
            count = count + (backpack.counts[id] or 0) + (equipment.counts[id] or 0)
        end
        if count == 0 then
            nexus = { available = true, counts = {} }
        elseif count == 1 then
            nexus = readSource(953)
        end
        local harnessCount = (backpack.counts[spikes.harnessId] or 0)
            + (equipment.counts[spikes.harnessId] or 0)
        if harnessCount == 0 then
            spikeHarness = { available = true, counts = {} }
        elseif harnessCount == 1 then
            spikeHarness = readSource(974)
        end
    end
    return { backpack = backpack, equipment = equipment, runeCounts = runes, nexus = nexus,
        spikeHarness = spikeHarness, inventionCharge = charge, signOfLifeCooldown = signOfLifeCooldown }
end

return reader
