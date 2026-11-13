-- Merge withdrawal messages without repeating counts from the fresh snapshot.
local alerts = {}

local function normaliseName(name)
    return type(name) == "string" and name:match("^%s*(.-)%s*$"):lower() or nil
end

function alerts.merge(tracked, messages)
    local names = {}
    for _, alert in ipairs(tracked) do
        local name = alert.itemId and normaliseName(alert.name)
        if name then names[name] = true end
    end
    for _, alert in ipairs(messages) do
        -- Charge percentages carry different information from inventory counts.
        if (alert.status and alert.status:match("%%$")) or not names[normaliseName(alert.name)] then
            tracked[#tracked + 1] = alert
        end
    end
    return tracked
end

return alerts
