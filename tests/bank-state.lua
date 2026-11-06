local watcher = require("bank-state").new()
local open, visible, restricted = false, true, false
var = { VarPlayer = { BANK_ACTIVE = { value = 1 } } }
ui = { Interfaces = {
    GetInterface = function() return open and {} or nil end,
    GetComponent = function() return { visibleGlobal = visible, isRestricted = restricted } end,
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
open = true
assert(not watcher.update())
restricted = true
assert(not watcher.update(), "an unreadable root does not imply closure")
open = false
assert(watcher.update(), "closure is detected after a temporarily unreadable root")
open, restricted = true, false
assert(not watcher.update())
restricted = true
var.VarPlayer.BANK_ACTIVE.value = 0
assert(watcher.update(), "inactive bank flag confirms closure when the root is unreadable")
assert(not watcher.update(), "closure is reported only once")
var.VarPlayer.BANK_ACTIVE.value = 1
restricted = false
assert(not watcher.update())
var.VarPlayer.BANK_ACTIVE.value = 0
assert(watcher.update(), "bank deactivation is detected even if the root remains visible")
assert(not watcher.update(), "bank deactivation is reported only once")
print("Bank close test watcher tests passed.")
