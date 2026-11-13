-- Resource percentages and shared artwork for settings and notifications.
local vitals = {
    { key = "health", name = "Health", threshold = 75, icon = { sprite = 24773 } },
    { key = "adrenaline", name = "Adrenaline", threshold = 100, icon = { sprite = 6935 } },
    { key = "prayer", name = "Prayer points", threshold = 75, icon = { sprite = 13197 } },
    { key = "summoning", name = "Summoning points", threshold = 50, icon = { sprite = 13216 } },
}

local function number(value)
    return type(value) == "number" and value >= 0 and value < math.huge
end

function vitals.read()
    local result = {}
    local function read(key, source)
        local ok, current, maximum = pcall(function()
            if not Player.IsAvailable() then return end
            return source()
        end)
        if ok and number(current) and number(maximum) and maximum > 0 then
            result[key] = current / maximum * 100
        end
    end
    read("health", function()
        return var.VarPlayer.LIFEPOINTS.value, var.VarPlayer.MAXLIFEPOINTS.value
    end)
    -- SA_ENERGY uses tenths of a percent; 100% is 1000, even with over-adrenaline.
    read("adrenaline", function() return var.VarPlayer.SA_ENERGY.value, 1000 end)
    read("prayer", function()
        -- PRAYER_POINTS uses 100 units per skill level (10 per displayed point).
        -- For example, 4413 / (99 * 100) is 44.58%, displayed as 441/990.
        return var.VarPlayer.PRAYER_POINTS.value, Player.GetLevelCapped(5) * 100
    end)
    read("summoning", function()
        return Player.GetLevelGameplay(23), Player.GetLevelCapped(23)
    end)
    return result
end

return vitals
