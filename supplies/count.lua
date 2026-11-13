-- Resolve a rule's count without treating unavailable sources as empty.
local spikes = require("supplies/armour-spikes")
local count = {}

function count.available(snapshot)
    return snapshot.backpack.available and snapshot.equipment.available
end

local function carried(snapshot, itemId)
    return (snapshot.backpack.counts[itemId] or 0) + (snapshot.equipment.counts[itemId] or 0)
end

function count.read(snapshot, itemId, item)
    if itemId == spikes.ruleId then
        if not count.available(snapshot) or not snapshot.spikeHarness
            or not snapshot.spikeHarness.available then return nil end
        local total = 0
        for _, id in ipairs(spikes.itemIds) do
            total = total + carried(snapshot, id) + (snapshot.spikeHarness.counts[id] or 0)
        end
        return total
    elseif item.godBook then
        if not snapshot.equipment.available then return nil end
        for _, id in ipairs(item.equippedIds or { itemId }) do
            if (snapshot.equipment.counts[id] or 0) > 0 then return snapshot.godBookTicks end
        end
    elseif item.inventionCharge then
        return snapshot.inventionCharge
    elseif item.combatVar then
        return snapshot.runeCounts and snapshot.runeCounts[itemId]
    elseif count.available(snapshot)
        and (not item.nexus or (snapshot.nexus and snapshot.nexus.available)) then
        return carried(snapshot, itemId) + (item.nexus and (snapshot.nexus.counts[itemId] or 0) or 0)
    end
end

return count
