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
print("Portal trigger tests passed.")
