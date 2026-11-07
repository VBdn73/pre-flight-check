local catalogue = require("supply-catalogue")
local spikes = require("armour-spikes")
local settings = require("warnings/settings")
local monitor = {}

function monitor.new(rules)
    local instance = {}

    function instance.update(snapshot)
        local alerts = {}
        for _, rule in ipairs(rules) do
            local effective = settings.effective(rules, rule)
            local item = rule.itemId == spikes.ruleId and spikes or catalogue[rule.itemId]
            local count
            if rule.itemId == spikes.ruleId then
                if snapshot.backpack.available and snapshot.equipment.available
                    and snapshot.spikeHarness and snapshot.spikeHarness.available then
                    count = 0
                    for _, itemId in ipairs(spikes.itemIds) do
                        count = count + (snapshot.backpack.counts[itemId] or 0)
                            + (snapshot.equipment.counts[itemId] or 0)
                            + (snapshot.spikeHarness.counts[itemId] or 0)
                    end
                end
            elseif item.combatVar then
                count = snapshot.runeCounts and snapshot.runeCounts[rule.itemId]
            elseif snapshot.backpack.available and snapshot.equipment.available
                and (not item.nexus or (snapshot.nexus and snapshot.nexus.available)) then
                count = (snapshot.backpack.counts[rule.itemId] or 0)
                    + (snapshot.equipment.counts[rule.itemId] or 0)
                if item.nexus then count = count + (snapshot.nexus.counts[rule.itemId] or 0) end
            end
            if rule.enabled and count ~= nil and count > 0 then
                local level
                if count < effective.critical then level = "critical"
                elseif count < effective.low then level = "low" end
                if level then
                    alerts[#alerts + 1] = { itemId = rule.itemId,
                        name = item.name, count = count, level = level }
                end
            end
        end
        return alerts
    end
    return instance
end

return monitor
