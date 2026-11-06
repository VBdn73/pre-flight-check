local watcher = require("bank-state").new()
local open, visible = false, true
var = { VarPlayer = { BANK_ACTIVE = { value = 1 } } }
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
open = true
assert(watcher.isOpen())
assert(watcher.isMainPanelOpen())
var.VarPlayer.BANK_ACTIVE.value = 0
assert(not watcher.isMainPanelOpen())
var.VarPlayer.BANK_ACTIVE.value = 1
watcher.markOpen()
open = false
assert(watcher.update(), "key event can mark a briefly opened bank")
print("Bank close test watcher tests passed.")
