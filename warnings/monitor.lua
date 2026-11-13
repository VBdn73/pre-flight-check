local catalogue = require("supplies/catalogue")
local spikes = require("supplies/armour-spikes")
local settings = require("warnings/settings")
local supplyCount = require("supplies/count")
local vitals = require("supplies/vitals")
local constants = require("constants")
local monitor = {}

function monitor.new(rules)
    local instance = {}

    function instance.update(snapshot)
        local alerts = {}
        for _, vital in ipairs(vitals) do
            local percent = snapshot.vitals and snapshot.vitals[vital.key]
            if rules[vital.key] and type(percent) == "number" and percent >= 0
                and percent < rules[vital.key .. "Threshold"] then
                alerts[#alerts + 1] = { name = vital.name, icon = vital.icon, level = "low",
                    message = string.format("%s: %d%% remaining", vital.name, math.floor(percent)) }
            end
        end
        if rules.deathReclaim and snapshot.deathReclaim then
            alerts[#alerts + 1] = { name = "Death reclaim",
                message = "Items may be awaiting reclaim from Death", level = "critical" }
        end
        if rules.signOfLife and type(snapshot.signOfLifeCooldown) == "number" and snapshot.signOfLifeCooldown > 0 then
            alerts[#alerts + 1] = { name = "Sign of life",
                message = "Sign of life: " .. snapshot.signOfLifeCooldown .. " min", level = "critical" }
        end
        if rules.excalibur and type(snapshot.excaliburCooldown) == "number" and snapshot.excaliburCooldown > 0 then
            alerts[#alerts + 1] = { name = "Excalibur",
                message = "Excalibur is on cooldown", level = "critical" }
        end
        if rules.powerburst and type(snapshot.powerburstCooldown) == "number" and snapshot.powerburstCooldown > 0 then
            alerts[#alerts + 1] = { name = "Powerburst",
                message = "Powerburst is on cooldown", level = "critical" }
        end
        if rules.sigilCooldowns then
            for _, cooldown in ipairs(snapshot.sigilCooldowns or {}) do
                alerts[#alerts + 1] = { name = cooldown.name,
                    message = cooldown.name .. " is on cooldown (" .. cooldown.seconds .. "s)",
                    level = "critical" }
            end
        end
        for _, rule in ipairs(rules) do
            local effective = settings.effective(rules, rule)
            local item = rule.itemId == spikes.ruleId and spikes or catalogue[rule.itemId]
            local count = supplyCount.read(snapshot, rule.itemId, item)
            -- Ordinary supplies are only tracked when carried; equipped books and
            -- the global Invention charge pool can still need warnings at zero.
            -- Book thresholds are in minutes.
            local timed = item.godBook
            if rule.enabled and count ~= nil and (count > 0 or timed or (item.inventionCharge and count == 0)) then
                local level
                local comparable = timed and count * constants.SERVER_TICK_SECONDS or count
                local scale = timed and constants.SECONDS_PER_MINUTE or 1
                if comparable < effective.critical * scale then level = "critical"
                elseif comparable < effective.low * scale then level = "low" end
                if level then
                    local alert = { itemId = rule.itemId, name = item.name, count = count, level = level }
                    if timed then
                        local seconds = math.floor(count * constants.SERVER_TICK_SECONDS)
                        alert.message = string.format("%s: %d:%02d:%02d remaining", item.name,
                            math.floor(seconds / constants.SECONDS_PER_HOUR),
                            math.floor(seconds / constants.SECONDS_PER_MINUTE) % constants.SECONDS_PER_MINUTE,
                            seconds % constants.SECONDS_PER_MINUTE)
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
