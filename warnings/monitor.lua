-- Time is supplied in seconds by the caller so cooldowns can be tested independently.
local catalogue = require("supply-catalogue")
local monitor = {}

function monitor.new(rules)
    local states = {}
    local instance = {}

    function instance.reset()
        states = {}
    end

    function instance.update(snapshot, now)
        if not snapshot.backpack.available or not snapshot.equipment.available then
            return {} -- Retain cooldowns; unavailable counts cannot trigger warnings.
        end
        local alerts = {}
        for _, rule in ipairs(rules) do
            if rule.enabled then
                local state = states[rule.itemId] or {}
                states[rule.itemId] = state
                local count = (snapshot.backpack.counts[rule.itemId] or 0)
                    + (snapshot.equipment.counts[rule.itemId] or 0)
                local level
                if count > 0 or rule.warnAtZero then
                    if count < rule.critical then level = "critical"
                    elseif count < rule.low then level = "low" end
                end
                if level then
                    local cooldown = level == "critical" and rule.criticalCooldown or rule.lowCooldown
                    local escalated = level == "critical" and state.level ~= "critical"
                    if escalated or not state.lastAlert or now - state.lastAlert >= cooldown then
                        alerts[#alerts + 1] = { itemId = rule.itemId,
                            name = catalogue[rule.itemId].name, count = count, level = level }
                        state.lastAlert = now
                    end
                end
                state.level = level
            else
                states[rule.itemId] = nil
            end
        end
        return alerts
    end
    return instance
end

return monitor
