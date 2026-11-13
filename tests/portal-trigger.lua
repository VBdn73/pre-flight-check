local trigger = require("warnings/portal-trigger")
local start = { level = 0, x = 3294, z = 10137 }
local destination = { level = 0, x = 4609, z = 5130 }
for id, tile in pairs({ [114761] = {3283,10149}, [114762] = {3290,10154},
    [114763] = {3298,10154}, [114764] = {3305,10149} }) do
    local entry = { verbText = "Enter", actionType = 2,
        locData = { config = { id = id }, coordGridX = tile[1], coordGridZ = tile[2] } }
    local pending = assert(trigger.begin(entry, 1, start))
    local arrived
    pending, arrived = trigger.advance(pending, 2, { level = 0, x = tile[1], z = tile[2] - 1 })
    assert(pending and not arrived, "approach does not trigger")
    pending, arrived = trigger.advance(pending, 3, nil)
    assert(pending and not arrived, "loading waits")
    pending, arrived = trigger.advance(pending, 4, destination)
    assert(not pending and arrived, "arrival consumes pending check")
    pending = trigger.begin(entry, 1, start)
    pending, arrived = trigger.advance(pending, 31, destination)
    assert(not pending and not arrived, "timeout is silent")
    entry.verbText = "Retune"
    assert(not trigger.begin(entry, 1, start))
    entry.verbText = "Enter"
    assert(not trigger.begin(entry, 1, destination))
    entry.locData.config.id = 1
    assert(not trigger.begin(entry, 1, start))
end
assert(not trigger.begin(nil, 1, start))
assert(not trigger.position(), "unavailable API is safe")

local entry = { verbText = "Enter", actionType = 2,
    locData = { config = { id = 114762 }, coordGridX = 3290, coordGridZ = 10154 } }
for _, case in ipairs({
    { "exact approach limit", 3306, 10154, 3371, 10154, true },
    { "outside approach limit", 3307, 10154, 3372, 10154, false },
    { "exact jump limit", 3290, 10154, 3354, 10154, false },
    { "beyond jump limit", 3290, 10154, 3355, 10154, true },
    { "small mapsquare crossing", 3290, 10175, 3290, 10176, false },
}) do
    local name, x, z, nextX, nextZ, expected = table.unpack(case)
    local pending = assert(trigger.begin(entry, 1, { level = 0, x = x, z = z }))
    local remaining, arrived = trigger.advance(pending, 2, { level = 0, x = nextX, z = nextZ })
    assert(not remaining and arrived == expected, name)
end
entry.locData.coordGridX = 3291
assert(not trigger.begin(entry, 1, start), "known config at the wrong tile is ignored")
entry.locData.coordGridX, entry.actionType = 3290, 1
assert(not trigger.begin(entry, 1, start), "only location entry actions are accepted")

local coord = { level = 0, x = 3290, z = 10154 }
Player = { IsAvailable = function() return true end,
    GetEntity = function() return { coordGrid = coord } end }
local captured = assert(trigger.position())
coord.x = 1
assert(captured.x == 3290, "positions are copied from client proxies")
coord.z = "invalid"
assert(not trigger.position(), "malformed coordinates are ignored")
Player.IsAvailable = function() return false end
assert(not trigger.position(), "unavailable players are ignored")
print("Portal trigger tests passed.")
