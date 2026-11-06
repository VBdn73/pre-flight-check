-- Legacy stateless threshold decisions, retained separately from the active monitor.
local catalogue = require("supply-catalogue")
local warnings = {}

-- Exact items only. These defaults can later be replaced with user settings.
warnings.defaults = {
    { itemId = 563, threshold = 100 },
    { itemId = 565, threshold = 100 },
    { itemId = 52299, threshold = 100 },
}

function warnings.evaluate(snapshot, rules)
    if not snapshot.backpack.available or not snapshot.equipment.available then
        return nil -- Unknown is not a zero quantity.
    end
    local low = {}
    for _, rule in ipairs(rules or warnings.defaults) do
        local total = (snapshot.backpack.counts[rule.itemId] or 0)
            + (snapshot.equipment.counts[rule.itemId] or 0)
        if total < rule.threshold then
            low[#low + 1] = { itemId = rule.itemId, name = catalogue[rule.itemId].name,
                count = total, threshold = rule.threshold }
        end
    end
    return low
end

return warnings
