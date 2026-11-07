local reader = require("inventory-reader")
local warningSettings = require("warnings/settings")
local settingsView = require("warnings/settings-view")
local warningMonitor = require("warnings/monitor")
local popup = require("warnings/popup")
local quiverDiagnostic = require("quiver-diagnostic")
local presetTrigger = require("preset-trigger")
local bankState = require("bank-state").new()
local prettyUILibrary = prettyui
local rules = warningSettings.load()
local monitor = warningMonitor.new(rules)
local refreshSettings, destroySettings
local canRead = true
local now
local checkAfter, checkDeadline
local anticipatedCloseUntil
local presetSettleDelay = 0.6 -- Allow a server tick for the preset's supply data to arrive.

-- Wait for server updates following the action before taking a fresh snapshot.
local function scheduleCheck(delay)
    if not canRead or not now then return end
    checkAfter, checkDeadline = now + delay, now + 5
end

local function anticipateClose(alwaysCheck, delay)
    if alwaysCheck or not anticipatedCloseUntil then scheduleCheck(delay or 0) end
    anticipatedCloseUntil = now + 5
end

local function refresh()
    if canRead then quiverDiagnostic.update() end
    local snapshot = canRead and reader.read() or {
        backpack = { available = false }, equipment = { available = false },
    }
    if not snapshot.backpack.available or not snapshot.equipment.available then popup.clear() end
    if not canRead or not now or not checkAfter or now < checkAfter then return end
    if not snapshot.backpack.available or not snapshot.equipment.available then
        if now >= checkDeadline then checkAfter, checkDeadline = nil, nil end
        return
    end
    checkAfter, checkDeadline = nil, nil
    local alerts = monitor.update(snapshot)
    if #alerts > 0 then popup.show(alerts, now, rules.popupDuration) end
end

Event.ServerLogic.Subscribe("supplyCheck.refresh", refresh)
Event.Logic.Subscribe("supplyCheck.clock", function(event)
    now = event.logicTick / 50
    popup.update(now)
    if anticipatedCloseUntil and now >= anticipatedCloseUntil then anticipatedCloseUntil = nil end
    if canRead and bankState.update() then
        if rules.checkOnBankClose and not anticipatedCloseUntil then scheduleCheck(0) end
        anticipatedCloseUntil = nil
    end
    if refreshSettings and not pcall(refreshSettings) then
        refreshSettings = nil
        if destroySettings then pcall(destroySettings); destroySettings = nil end
    end
end)
Event.KeyDown.Subscribe("supplyCheck.presetShortcut", function(event)
    if not canRead or not now or not bankState.isMainPanelOpen() then return end
    if event.gameKey == 13 and not event.isRepeat and rules.checkOnBankClose then -- Escape
        local ok, usable = pcall(function() return Keyboard.IsAvailable() and not Keyboard.IsBlocked() end)
        if not ok or not usable then return end
        anticipateClose()
        return
    end
    if not rules.checkOnPreset and not rules.checkOnBankClose then return end
    local modifiers = event.modifiers
    local ok, ctrl, shift, alt = pcall(function()
        if not Keyboard.IsAvailable() or Keyboard.IsBlocked() then return nil end
        return Keyboard.IsControlDown(), Keyboard.IsShiftDown(), Keyboard.IsAltDown()
    end)
    if ok and ctrl ~= nil then
        modifiers = (ctrl and 2 or 0) + (shift and 1 or 0) + (alt and 4 or 0)
    end
    if presetTrigger.isShortcut(event, modifiers) then
        bankState.markOpen()
        if rules.checkOnBankClose then anticipateClose(true, presetSettleDelay)
        elseif rules.checkOnPreset then scheduleCheck(presetSettleDelay) end
    end
end)
Event.SettingsLayerReady.Subscribe("supplyCheck.settings", function(event)
    if destroySettings then pcall(destroySettings) end
    refreshSettings, destroySettings = nil, nil
    local ok, result, destroy = pcall(settingsView.build, event.component, rules, function()
        popup.clear()
    end, prettyUILibrary)
    if ok then
        refreshSettings, destroySettings = result, destroy
    else
        print("[supply-check] Settings creation failed: " .. tostring(result))
    end
end)
Event.MiniMenuEntrySelected.Subscribe("supplyCheck.preset", function(event)
    if not presetTrigger.isLoad(event.entry) then return end
    if rules.checkOnBankClose and canRead and now and bankState.isMainPanelOpen() then
        bankState.markOpen()
        anticipateClose(true, presetSettleDelay)
    elseif rules.checkOnPreset then
        scheduleCheck(presetSettleDelay)
    end
end)
Event.GameStateChanged.Subscribe("supplyCheck.state", function(event)
    canRead = event.newState == 30 -- GameState.GAME
    if not canRead then
        quiverDiagnostic.reset()
        popup.clear()
        bankState.reset()
        checkAfter, checkDeadline = nil, nil
        anticipatedCloseUntil = nil
    end
    refresh()
end)

function PluginShutdown()
    refreshSettings = nil
    if destroySettings then pcall(destroySettings); destroySettings = nil end
    popup.clear()
    Event.ServerLogic.Unsubscribe("supplyCheck.refresh")
    Event.Logic.Unsubscribe("supplyCheck.clock")
    Event.KeyDown.Unsubscribe("supplyCheck.presetShortcut")
    Event.SettingsLayerReady.Unsubscribe("supplyCheck.settings")
    Event.MiniMenuEntrySelected.Unsubscribe("supplyCheck.preset")
    Event.GameStateChanged.Unsubscribe("supplyCheck.state")
end
