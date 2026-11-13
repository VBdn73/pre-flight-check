-- Match observed War's Retreat portal slots, then detect travel rather than clicks.
local trigger = {}
local MAPSQUARE_SIZE = 64
local RETREAT_MAPSQUARE_X, RETREAT_MAPSQUARE_Z, RETREAT_LEVEL = 51, 158, 0
local ENTER_LOCATION_ACTION = 2
local ATTEMPT_TIMEOUT_SECONDS = 30
local PORTAL_APPROACH_TILES, TRAVEL_JUMP_TILES = 16, 64
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
    return position and position.level == RETREAT_LEVEL
        and math.floor(position.x / MAPSQUARE_SIZE) == RETREAT_MAPSQUARE_X
        and math.floor(position.z / MAPSQUARE_SIZE) == RETREAT_MAPSQUARE_Z
end

function trigger.begin(entry, now, position)
    local ok, pending = pcall(function()
        if not entry or entry.verbText ~= "Enter" or entry.actionType ~= ENTER_LOCATION_ACTION
            or not inRetreat(position) then return nil end
        local loc = entry.locData
        local expected = loc and loc.config and portals[loc.config.id]
        if not expected or loc.coordGridX ~= expected[1] or loc.coordGridZ ~= expected[2] then return nil end
        -- Retain primitives only, not client menu/config proxies.
        return { deadline = now + ATTEMPT_TIMEOUT_SECONDS, previous = position,
            portalX = loc.coordGridX, portalZ = loc.coordGridZ }
    end)
    return ok and pending or nil
end

function trigger.advance(pending, now, position)
    if now >= pending.deadline then return nil, false end
    if not position then return pending, false end
    local previous = pending.previous
    local near = math.max(math.abs(previous.x - pending.portalX),
        math.abs(previous.z - pending.portalZ)) <= PORTAL_APPROACH_TILES
    local jumped = math.max(math.abs(position.x - previous.x),
        math.abs(position.z - previous.z)) > TRAVEL_JUMP_TILES
    if not inRetreat(position) then return nil, near and jumped end
    pending.previous = position
    return pending, false
end
return trigger
