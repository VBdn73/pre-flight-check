local catalogue = require("supply-catalogue")
local spikes = require("armour-spikes")
local settings = require("warnings/settings")
local monitor = {}

function monitor.new(rules)
    local instance = {}

    function instance.update(snapshot)
        local alerts = {}
        if rules.deathReclaim and snapshot.deathReclaim then
            alerts[#alerts + 1] = { name = "Death reclaim",
                message = "Items may be awaiting reclaim from Death", level = "critical" }
        end
        if rules.signOfLife and type(snapshot.signOfLifeCooldown) == "number" and snapshot.signOfLifeCooldown > 0 then
            alerts[#alerts + 1] = { name = "Sign of life",
                message = "Sign of life: " .. snapshot.signOfLifeCooldown .. " min", level = "critical" }
        end
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
            elseif item.godBook then
                if snapshot.equipment.available and (snapshot.equipment.counts[rule.itemId] or 0) > 0 then
                    count = snapshot.godBookTicks
                end
            elseif item.inventionCharge then
                count = snapshot.inventionCharge
            elseif item.combatVar then
                count = snapshot.runeCounts and snapshot.runeCounts[rule.itemId]
            elseif snapshot.backpack.available and snapshot.equipment.available
                and (not item.nexus or (snapshot.nexus and snapshot.nexus.available)) then
                count = (snapshot.backpack.counts[rule.itemId] or 0)
                    + (snapshot.equipment.counts[rule.itemId] or 0)
                if item.nexus then count = count + (snapshot.nexus.counts[rule.itemId] or 0) end
            end
            local timed = item.godBook
            if rule.enabled and count ~= nil and (count > 0 or timed) then
                local level
                local comparable = timed and count * 0.6 or count
                local scale = timed and 60 or 1
                if comparable < effective.critical * scale then level = "critical"
                elseif comparable < effective.low * scale then level = "low" end
                if level then
                    local alert = { itemId = rule.itemId, name = item.name, count = count, level = level }
                    if timed then
                        local seconds = math.floor(count * 0.6)
                        alert.message = string.format("%s: %d:%02d:%02d remaining", item.name,
                            math.floor(seconds / 3600), math.floor(seconds / 60) % 60, seconds % 60)
                    end
                    alerts[#alerts + 1] = alert
                end
            end
        end
        return alerts
    end
    return instance
end

return monitor
