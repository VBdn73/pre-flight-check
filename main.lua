local reader = require("inventory-reader")
local view = require("supply-view")
local warningSettings = require("warnings/settings")
local settingsView = require("warnings/settings-view")
local warningMonitor = require("warnings/monitor")
local popup = require("warnings/popup")
local diagnostic = require("rune-diagnostic")
local quiverDiagnostic = require("quiver-diagnostic")
local prettyUILibrary = prettyui
local rules = warningSettings.load()
local monitor = warningMonitor.new(rules)
local refreshContent
local refreshSettings, destroySettings
local canRead = true
local now
local retryAfter = 0

local function refresh()
    if canRead then
        diagnostic.update()
        quiverDiagnostic.update()
    end
    local snapshot = canRead and reader.read() or {
        backpack = { available = false }, equipment = { available = false },
    }
    if not snapshot.backpack.available or not snapshot.equipment.available then popup.clear() end
    if refreshContent then
        local ok, err = pcall(refreshContent, snapshot)
        if not ok then
            refreshContent = nil
            print("[supply-check] Panel refresh stopped: " .. tostring(err))
        end
    end
    if canRead and now and now >= retryAfter then
        local alerts = monitor.update(snapshot, now)
        if #alerts > 0 and not popup.show(alerts, now) then
            monitor.reset()
            retryAfter = now + 10
        end
    end
end

Event.ContentLayerReady.Subscribe("supplyCheck.content", function(event)
    refreshContent = nil
    local ok, result = pcall(view.build, event.component)
    if not ok then
        print("[supply-check] Panel creation failed: " .. tostring(result))
        return
    end
    refreshContent = result
    refresh()
end)

Event.ServerLogic.Subscribe("supplyCheck.refresh", refresh)
Event.Logic.Subscribe("supplyCheck.clock", function(event)
    now = event.logicTick / 50
    popup.update(now)
    if refreshSettings and not pcall(refreshSettings) then
        refreshSettings = nil
        if destroySettings then pcall(destroySettings); destroySettings = nil end
    end
end)
Event.SettingsLayerReady.Subscribe("supplyCheck.settings", function(event)
    if destroySettings then pcall(destroySettings) end
    refreshSettings, destroySettings = nil, nil
    local ok, result, destroy = pcall(settingsView.build, event.component, rules, function()
        monitor.reset()
        popup.clear()
        retryAfter = 0
    end, prettyUILibrary)
    if ok then
        refreshSettings, destroySettings = result, destroy
    else
        print("[supply-check] Settings creation failed: " .. tostring(result))
    end
end)
Event.GameStateChanged.Subscribe("supplyCheck.state", function(event)
    canRead = event.newState == 30 -- GameState.GAME
    if not canRead then
        diagnostic.reset()
        quiverDiagnostic.reset()
        monitor.reset()
        popup.clear()
    end
    refresh()
end)

function PluginShutdown()
    refreshContent = nil
    refreshSettings = nil
    if destroySettings then pcall(destroySettings); destroySettings = nil end
    popup.clear()
    Event.ContentLayerReady.Unsubscribe("supplyCheck.content")
    Event.ServerLogic.Unsubscribe("supplyCheck.refresh")
    Event.Logic.Unsubscribe("supplyCheck.clock")
    Event.SettingsLayerReady.Unsubscribe("supplyCheck.settings")
    Event.GameStateChanged.Unsubscribe("supplyCheck.state")
end
