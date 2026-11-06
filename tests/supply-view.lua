local view = require("supply-view")
local text = view.format({ backpack = { available = true, counts = { [563] = 67 } },
    equipment = { available = true, counts = { [563] = 5, [52299] = 42 } } })
assert(text:find("Backpack: 67 | Equipment: 5<br>Total: 72", 1, true))
assert(text:find("Backpack: 0 | Equipment: 42<br>Total: 42", 1, true))
assert(text:find("Pouches, quivers and other containers excluded.", 1, true))
text = view.format({ backpack = { available = true, counts = {} }, equipment = { available = false } })
assert(text:find("Backpack: 0 | Equipment: unavailable<br>Total: unavailable", 1, true))

-- Exercise the real panel refresh: unchanged snapshots must not rewrite the UI,
-- while source availability and counts must immediately change the displayed text.
local controls, writes = {}, 0
ui = { Text = { new = function(parent)
    local control = { SetPos = function() end, SetSize = function() end }
    -- Keep content assignments observable even after the first write.
    local values = {}
    setmetatable(control, {
        __index = function(t, key) return values[key] end,
        __newindex = function(t, key, value)
            if key == "content" then writes = writes + 1 end
            values[key] = value
        end,
    })
    controls[#controls + 1] = control
    return control
end } }
id = { Font = { MUSEO_SANS_15PT_REGULAR = 1 } }
local refresh = view.build({})
local snapshot = { backpack = { available = true, counts = { [563] = 67 } },
    equipment = { available = true, counts = {} } }
refresh(snapshot)
local afterFirst = writes
refresh(snapshot)
assert(writes == afterFirst, "unchanged snapshots should not rewrite content")
snapshot.backpack.counts[563] = 66
refresh(snapshot)
assert(writes == afterFirst + 1 and controls[2].content:find("Backpack: 66", 1, true))
snapshot.equipment = { available = false }
refresh(snapshot)
assert(writes == afterFirst + 2 and controls[2].content:find("Total: unavailable", 1, true))
print("Supply view tests passed.")
