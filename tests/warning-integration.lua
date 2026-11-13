local callbacks = {}
local function event(name)
    return { Subscribe = function(_, cb) callbacks[name] = cb end, Unsubscribe = function() end }
end
Event = { Logic = event("logic"), ServerLogic = event("server"), GameStateChanged = event("state"),
    SettingsLayerReady = event("settings"), ContentLayerReady = event("content"),
    MiniMenuEntrySelected = event("menu"), KeyDown = event("key"), ChatMessage = event("chat") }
PluginPermissions = { chatAccess = 1 }
local chatPermission = true
Plugin = { HasPermission = function() return chatPermission end }
local amount, available, bankOpen, bankRestricted = 200, true, false, false
var = { VarPlayer = { BANK_ACTIVE = { value = 1 } } }
Keyboard = { IsAvailable = function() return true end, IsBlocked = function() return false end,
    IsControlDown = function() return false end, IsShiftDown = function() return false end,
    IsAltDown = function() return false end }
ui = { Interfaces = { GetInterface = function() return bankOpen and {} or nil end,
    GetComponent = function() return { visibleGlobal = true, isRestricted = bankRestricted } end } }
package.loaded["supplies/inventory-reader"] = { read = function()
    return { backpack = { available = available, counts = {} }, equipment = { available = available, counts = {} },
        runeCounts = { [563] = amount } }
end }
local rules = { checkOnPreset = false, checkOnBankClose = false,
    { itemId = 563, enabled = true, warnAtZero = false, low = 100, critical = 25 } }
package.loaded["warnings/settings"] = { effective = function(_, rule) return rule end,
    load = function() return rules end }
package.loaded["warnings/settings-view"] = { build = function() end }
local alerts = {}
local lastBatch, lastTime, popupOpen
package.loaded["warnings/ribbon"] = { record = function(items, now) lastBatch, lastTime = items, now end,
    open = function() end, close = function() end, update = function() end }
package.loaded["warnings/popup"] = { show = function(items) popupOpen = true; alerts[#alerts + 1] = items; return true end,
    clear = function() popupOpen = false end, update = function() end }
dofile("main.lua")
local function time(seconds) callbacks.logic({ logicTick = seconds * 50 }) end
local function load() callbacks.menu({ entry = { verbText = "Load", componentData = { component = {
    interfaceID = 517, staticID = 267 } } } }) end
-- Preset checks wait for the new inventory and do not run continuously.
time(1)
callbacks.server()
amount = 99
time(2)
callbacks.server()
assert(#alerts == 0, "no continuous warnings")
load() -- disabled
time(4)
callbacks.server()
assert(#alerts == 0)
rules.checkOnPreset = true
load()
callbacks.server() -- The first update can still contain the previous preset.
assert(#alerts == 0, "preset check waits for supply data to settle")
amount = 80 -- server data changes after action
time(4.6)
callbacks.server()
assert(#alerts == 1 and alerts[1][1].count == 80, "preset check uses the settled snapshot")
assert(lastBatch == alerts[1] and lastTime == 4.6, "ribbon records the notification batch at trigger time")
time(6)
callbacks.server()
assert(#alerts == 1, "server updates do not repeat the check")
load()
time(8)
callbacks.server()
assert(#alerts == 2, "repeated preset loads check again")
bankOpen = true
time(9)
callbacks.key({ gameKey = 16, modifiers = 0, isRepeat = false })
amount = 70
time(10.2)
callbacks.server()
assert(#alerts == 3 and alerts[3][1].count == 70, "shortcut checks the settled snapshot")
-- Bank-close checks, unavailable inventory, and Escape deduplication.
rules.checkOnPreset = false
rules.checkOnBankClose = true
bankRestricted = true
time(11)
bankOpen = false
time(12)
callbacks.server()
assert(#alerts == 4, "bank closure checks on the next server update without a delay")
bankRestricted = false
bankOpen = true
time(15)
bankOpen = false
time(16)
available = false
time(18)
callbacks.server()
assert(#alerts == 4, "unavailable inventory cannot trigger a check")
available = true
time(19)
callbacks.server()
assert(#alerts == 5, "pending check retries when inventory returns")
bankOpen = true
time(20)
callbacks.key({ gameKey = 13, isRepeat = false })
callbacks.server()
assert(#alerts == 6, "Escape checks on the next server update before bank state changes")
var.VarPlayer.BANK_ACTIVE.value = 0 -- Escape can leave the root visible.
time(21)
callbacks.server()
assert(#alerts == 6, "bank deactivation does not duplicate the Escape check")
time(22)
callbacks.server()
assert(#alerts == 6, "bank deactivation triggers only one check")
var.VarPlayer.BANK_ACTIVE.value = 1
time(23)
callbacks.key({ gameKey = 13, isRepeat = false })
callbacks.server()
assert(#alerts == 7, "Escape can trigger a check after the bank is reopened")
time(29) -- Escape did not close the bank; a later close must still trigger.
bankOpen = false
time(30)
callbacks.server()
assert(#alerts == 8, "a later bank close is not suppressed indefinitely")
time(40)
callbacks.server()
assert(#alerts == 8, "server updates do not repeat alerts")
-- Preset loads and bank closure must not generate duplicate or stale checks.
bankOpen = true
time(41)
load()
callbacks.server()
bankOpen = false
time(41.5)
callbacks.server()
assert(#alerts == 8, "bank closure does not replace the pending preset check")
time(41.7)
callbacks.server()
assert(#alerts == 9, "bank-close-only menu preset checks after settling")
bankOpen = true
time(43)
callbacks.key({ gameKey = 16, modifiers = 0, isRepeat = false })
callbacks.server()
bankOpen = false
time(43.5)
callbacks.server()
assert(#alerts == 9, "shortcut closure does not check stale data")
time(43.7)
callbacks.server()
assert(#alerts == 10, "bank-close-only preset shortcut checks after settling")
bankOpen = true
time(45)
rules.checkOnPreset = true
load()
time(46.2)
callbacks.server()
load()
time(47.5)
callbacks.server()
assert(#alerts == 12, "repeated preset loads check even when both triggers are enabled")
bankOpen = false
time(48)
callbacks.server()
assert(#alerts == 12, "both triggers do not duplicate the close check")
bankOpen = true
time(49)
amount = 10
load()
callbacks.server()
assert(#alerts == 12, "old low preset does not alert during a new load")
amount = 200
time(50.3)
callbacks.server()
assert(#alerts == 12, "a well-stocked preset does not inherit the previous warning")
assert(#lastBatch == 0 and lastTime == 50.3, "a clean check replaces the previous batch")
assert(not popupOpen, "a clean check closes the previous popup, including when pinned")
load()
amount = 10
time(51.6)
callbacks.server()
assert(#alerts == 13 and alerts[13][1].count == 10, "a low newly loaded preset still warns")
assert(lastBatch == alerts[13], "a new notification replaces the previous batch")
rules[1].enabled = false
load()
time(52.9)
callbacks.server()
assert(#alerts == 13, "disabled items do not alert on a triggered check")
-- Death reclaim follows the same trigger and enabled-setting rules.
rules.deathReclaim = true
var.VarPlayer.GRAVESTONE_TIMER_INV_SLOTS = { value = 2 }
-- The reader mock supplies the same snapshot field as the real reader.
package.loaded["supplies/inventory-reader"].read = function()
    return { backpack = { available = true, counts = {} }, equipment = { available = true, counts = {} },
        deathReclaim = true, runeCounts = {} }
end
callbacks.server()
assert(#alerts == 13, "death reclaim does not warn without a check")
load()
time(54.2)
callbacks.server()
assert(#alerts == 14 and alerts[14][1].name == "Death reclaim")
load()
time(55.5)
callbacks.server()
assert(#alerts == 15, "unclaimed items warn on repeated checks")
rules.deathReclaim = false
load()
time(56.8)
callbacks.server()
assert(#alerts == 15, "disabled death reclaim warning stays silent")
-- Preset chat notifications require opt-in and permission.
rules.checkOnPreset = true
local function chat(text, kind) callbacks.chat({ chatMessage = text, chatType = kind or 0 }) end
time(57)
chat("Your preset is being withdrawn. Please see below for any issues whilst trying to load it...", 109)
chat("Item could not be found: Powder of protection", 109)
time(57.7)
assert(#alerts == 15, "chat notifications are opt-in")
rules.presetChatNotifications = true
time(58)
chat("Your preset is being withdrawn. Please see below for any issues whilst trying to load it...", 109)
chat("Item could not be found: Powder of protection", 109)
chat("Super prayer renewal potion (2) could not be found. Super prayer renewal potion (6) was loaded instead.", 109)
chat("Item could not be found in the quantity required: Ectoplasm", 109)
chat("Item could not be found: Fake", 2)
time(58.7)
assert(#alerts == 16 and #alerts[16] == 3, "preset game messages form one notification batch")
assert(alerts[16][1].level == "critical" and alerts[16][2].level == "low")
assert(lastBatch == alerts[16], "preset issues reach the ribbon")
chatPermission = false
chat("Your preset is being withdrawn. Please see below for any issues whilst trying to load it...")
chat("Item could not be found: Powder of protection")
time(60)
assert(#alerts == 16, "no chat notifications without permission")
-- Merge chat issues with supply warnings without losing unmatched issues.
chatPermission = true
rules[1].enabled = true
package.loaded["supplies/inventory-reader"].read = function()
    return { backpack = { available = true, counts = {} }, equipment = { available = true, counts = {} },
        runeCounts = { [563] = 10 } }
end
time(61)
load()
chat("Your preset is being withdrawn. Please see below for any issues whilst trying to load it...", 109)
chat("Item could not be found in the quantity required: LAW RUNE", 109)
chat("Item could not be found: Powder of penance", 109)
time(61.7)
assert(#alerts == 17 and #alerts[17] == 2, "tracked and chat warnings for the same item are merged")
assert(alerts[17][1].name == "Law rune" and alerts[17][1].count == 10, "quantity warning is retained")
assert(alerts[17][2].name == "Powder of penance", "unmatched chat warning is retained")
package.loaded["supplies/inventory-reader"].read = function()
    return { backpack = { available = true, counts = {} }, equipment = { available = true, counts = {} },
        runeCounts = { [563] = 0 } }
end
time(63)
load()
chat("Your preset is being withdrawn. Please see below for any issues whilst trying to load it...", 109)
chat("Item could not be found: Law rune", 109)
time(63.7)
assert(#alerts == 18 and #alerts[18] == 1 and alerts[18][1].status == "MISSING", "missing warning remains when no quantity alert is available")
time(65)
chat("Your preset is being withdrawn. Please see below for any issues whilst trying to load it...", 109)
chat("Item could not be found: Powder of protection", 109)
rules.presetChatNotifications = false
time(66)
assert(#alerts == 18, "disabling chat notifications discards pending messages")
rules.presetChatNotifications = true
rules.checkOnPreset = false
chat("Your preset is being withdrawn. Please see below for any issues whilst trying to load it...", 109)
chat("Item could not be found: Powder of protection", 109)
time(67)
assert(#alerts == 18, "chat notifications require preset checks")
rules.checkOnPreset = true
-- Durability messages are opt-in and limited to the preset-load window.
rules.itemDurability = false
time(68)
load()
chat("Your Test platelegs has 3.9% of its charges left.", 109)
time(68.7)
assert(#alerts == 18, "durability warnings default off")
rules.itemDurability = true
time(70)
load()
chat("Your Test platelegs has 3.9% of its charges left.", 109)
time(70.7)
assert(#alerts == 19 and alerts[19][1].name == "Test platelegs" and alerts[19][1].status == "3.9%", "charge warning is displayed without a withdrawal header")
time(76)
chat("Your Test platelegs has 2% of its charges left.", 109)
time(77)
assert(#alerts == 19, "unrelated charge messages are ignored")
local bobMessage = "Unable to load beast of burden preset as this follower can't hold any items."
rules.beastOfBurden = false
time(78)
load()
chat(bobMessage, 109)
time(78.7)
assert(#alerts == 19, "disabled beast of burden warnings are ignored")
rules.beastOfBurden = true
time(80)
load()
chat(bobMessage, 109)
time(80.7)
assert(#alerts == 20 and alerts[20][1].name == "Beast of burden preset", "enabled beast of burden warning is displayed")
callbacks.state({ newState = 40 })
PluginShutdown()
print("Warning integration tests passed.")
