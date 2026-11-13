-- Match observed War's Retreat portal slots, then detect travel rather than clicks.
local trigger = {}
local portals = {
    [114761] = { 3283, 10149 }, -- Reaper
    [114762] = { 3290, 10154 }, -- First attuned
    [114763] = { 3298, 10154 }, -- Second attuned
    [114764] = { 3305, 10149 }, -- Featured
}

function trigger.position()
    local ok, position = pcall(function()
        if not Player.IsAvailable() then return nil end
        local coord = Player.GetEntity().coordGrid
        if type(coord.x) ~= "number" or type(coord.z) ~= "number"
            or type(coord.level) ~= "number" then return nil end
        return { x = coord.x, z = coord.z, level = coord.level }
    end)
    return ok and position or nil
end

local function inRetreat(position)
    return position and position.level == 0 and math.floor(position.x / 64) == 51
        and math.floor(position.z / 64) == 158
end

function trigger.begin(entry, now, position)
    local ok, pending = pcall(function()
        if not entry or entry.verbText ~= "Enter" or entry.actionType ~= 2
            or not inRetreat(position) then return nil end
        local loc = entry.locData
        local expected = loc and loc.config and portals[loc.config.id]
        if not expected or loc.coordGridX ~= expected[1] or loc.coordGridZ ~= expected[2] then return nil end
        -- Retain primitives only, not client menu/config proxies.
        return { deadline = now + 30, previous = position,
            portalX = loc.coordGridX, portalZ = loc.coordGridZ }
    end)
    return ok and pending or nil
end

function trigger.advance(pending, now, position)
    if now >= pending.deadline then return nil, false end
    if not position then return pending, false end
    local previous = pending.previous
    local near = math.max(math.abs(previous.x - pending.portalX),
        math.abs(previous.z - pending.portalZ)) <= 16
    local jumped = math.max(math.abs(position.x - previous.x),
        math.abs(position.z - previous.z)) > 64
    if not inRetreat(position) then return nil, near and jumped end
    pending.previous = position
    return pending, false
end
return trigger
