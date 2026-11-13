-- Read independent, fresh snapshots; never retain an Inventory proxy across calls.
local reader = {}
local catalogue = require("supplies/catalogue")
local spikes = require("supplies/armour-spikes")

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

local function readNonnegativeVar(group, name)
    local ok, value = pcall(function() return var[group][name].value end)
    if ok and integer(value, 0) then return value end
end

-- Only read a container when exactly one corresponding item is carried.
local function readCarriedContainer(backpack, equipment, ids, inventoryId)
    if not backpack.available or not equipment.available then return { available = false } end
    local count = 0
    for _, id in ipairs(ids) do
        count = count + (backpack.counts[id] or 0) + (equipment.counts[id] or 0)
    end
    -- Multiple containers cannot be attributed reliably to the shared inventory.
    if count == 0 then return { available = true, counts = {} } end
    if count == 1 then return readSource(inventoryId) end
    return { available = false }
end

function reader.read()
    local runes = {}
    local deathReclaim = false
    local deathKnown = true
    for _, name in ipairs({ "GRAVESTONE_TIMER_INV_SLOTS", "GRAVESTONE_TIMER_WORN_SLOTS",
        "GRAVESTONE_TIMER_OVERFLOW_SLOTS" }) do
        local value = readNonnegativeVar("VarPlayer", name)
        if value == nil then deathKnown = false
        elseif value > 0 then deathReclaim = true end
    end
    -- A positive slot count is conclusive even if another variable is unavailable.
    if not deathReclaim and not deathKnown then deathReclaim = nil end
    local bookTicks = readNonnegativeVar("VarPlayer", "GOD_BOOK_TIMELEFT")
    local signOfLifeCooldown = readNonnegativeVar("VarPlayer", "DIV_LIFE_COOLDOWN")
    local excaliburCooldown = readNonnegativeVar("VarPlayer", "COMBATV2_EXCALIBUR_SPEC")
    local powerburstCooldown = readNonnegativeVar("VarPlayer", "HERB_POW_COOLDOWN")
    local raw = readNonnegativeVar("VarPlayer", "INVENT_CHARGE")
    local charge = raw and math.floor(raw / 3000)
    for itemId, item in pairs(catalogue) do
        if item.combatVar then
            runes[itemId] = readNonnegativeVar("VarClient", item.combatVar)
        end
    end
    local backpack, equipment = readSource("INV"), readSource("WORN")
    -- Include uncharged nexus variants; their contents are not assumed empty.
    local nexus = readCarriedContainer(backpack, equipment, { 56141, 56142, 56143, 59358, 59359, 59360 }, 953)
    local spikeHarness = readCarriedContainer(backpack, equipment, { spikes.harnessId }, 974)
    return { backpack = backpack, equipment = equipment, runeCounts = runes, nexus = nexus,
        spikeHarness = spikeHarness, inventionCharge = charge, signOfLifeCooldown = signOfLifeCooldown,
        godBookTicks = bookTicks, deathReclaim = deathReclaim, excaliburCooldown = excaliburCooldown,
        powerburstCooldown = powerburstCooldown, sigilCooldowns = require("supplies/sigils").read(),
        vitals = require("supplies/vitals").read() }
end

return reader
