local watcher = require("bank-close-test").new()
local open, visible = false, true
ui = { Interfaces = {
    GetInterface = function() return open and {} or nil end,
    GetComponent = function() return { visibleGlobal = visible } end,
} }
assert(not watcher.update())
open = true
assert(not watcher.update())
assert(not watcher.update())
open = false
assert(watcher.update())
assert(not watcher.update())
open = true
assert(not watcher.update())
visible = false
assert(watcher.update())
visible = true
assert(not watcher.update())
watcher.reset()
open = false
assert(not watcher.update())
print("Bank close test watcher tests passed.")
