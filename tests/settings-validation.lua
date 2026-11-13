local settings = require("warnings/settings")

local function boundaries(name, validate, minimum, maximum)
    for _, value in ipairs({ minimum, maximum }) do
        assert(validate(value), name .. ": accepts " .. value)
    end
    for _, value in ipairs({ minimum - 1, maximum + 1, 1.5, "1", false, math.huge, 0 / 0 }) do
        assert(not validate(value), name .. ": rejects " .. tostring(value))
    end
    assert(not validate(nil), name .. ": rejects nil")
end

boundaries("duration", settings.validDuration, 1, 3600)
boundaries("rows", settings.validPopupRows, 1, 20)
boundaries("percentage", settings.validPercentage, 0, 100)
boundaries("adrenaline", function(value)
    return settings.validPercentage(value, "adrenalineThreshold")
end, 0, 150)

for _, case in ipairs({ { "quantity", 563, 1, 2147483647 }, { "book", 52494, 0, 1440 } }) do
    local name, itemId, minimum, maximum = table.unpack(case)
    boundaries(name, function(value)
        return settings.valid({ itemId = itemId, enabled = true, low = value, critical = minimum })
    end, minimum, maximum)
    assert(not settings.valid({ itemId = itemId, enabled = true, low = 10, critical = 11 }), name)
    assert(not settings.valid({ itemId = itemId, enabled = 1, low = 10, critical = 5 }), name)
end
assert(not settings.valid(nil))
assert(not settings.valid(false))
print("Settings validation tests passed.")
