-- Time is supplied in seconds by the caller so cooldowns can be tested independently.
local catalogue = require("supply-catalogue")
local spikes = require("armour-spikes")
local settings = require("warnings/settings")
local monitor = {}

function monitor.new(rules)
    local states = {}
    local instance = {}

    function instance.reset()
        states = {}
    end

    function instance.update(snapshot, now)
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
            if rule.enabled and count ~= nil then
                local state = states[rule.itemId] or {}
                states[rule.itemId] = state
                local level
                if count > 0 or effective.warnAtZero then
                    if count < effective.critical then level = "critical"
                    elseif count < effective.low then level = "low" end
                end
                if level then
                    local cooldown = level == "critical" and effective.criticalCooldown or effective.lowCooldown
                    local escalated = level == "critical" and state.level ~= "critical"
                    if escalated or not state.lastAlert or now - state.lastAlert >= cooldown then
                        alerts[#alerts + 1] = { itemId = rule.itemId,
                            name = item.name, count = count, level = level }
                        state.lastAlert = now
                    end
                end
                state.level = level
            elseif not rule.enabled then
                states[rule.itemId] = nil
            end
        end
        return alerts
    end
    return instance
end

return monitor
