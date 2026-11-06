local reader = require("inventory-reader")
local warningSettings = require("warnings/settings")
local settingsView = require("warnings/settings-view")
local warningMonitor = require("warnings/monitor")
local popup = require("warnings/popup")
local quiverDiagnostic = require("quiver-diagnostic")
local presetTest = require("preset-test")
local bankCloseTest = require("bank-close-test").new()
local prettyUILibrary = prettyui
local rules = warningSettings.load()
local monitor = warningMonitor.new(rules)
local refreshSettings, destroySettings
local canRead = true
local now
local retryAfter = 0
local presetWatcher = presetTest.newWatcher(print)
local lastTestAt

local function showTestNotification()
    if not now or not canRead then
        print("[supply-check] Test popup is available in-game once the client clock starts.")
        return
    end
    if not popup.show({ { name = "Test notification", count = 123, level = "low" } }, now) then
        print("[supply-check] Test popup could not be displayed.")
    end
end

local function refresh()
    if canRead then
        quiverDiagnostic.update()
    end
    local snapshot = canRead and reader.read() or {
        backpack = { available = false }, equipment = { available = false },
    }
    if not snapshot.backpack.available or not snapshot.equipment.available then popup.clear() end
    if canRead and now and now >= retryAfter then
        local alerts = monitor.update(snapshot, now)
        if #alerts > 0 and not popup.show(alerts, now) then
            monitor.reset()
            retryAfter = now + 10
        end
    end
end

Event.ServerLogic.Subscribe("supplyCheck.refresh", refresh)
Event.Logic.Subscribe("supplyCheck.clock", function(event)
    now = event.logicTick / 50
    popup.update(now)
    if canRead and bankCloseTest.update() and rules.testBankClose then
        showTestNotification()
    end
    if canRead and presetWatcher.update() and (not lastTestAt or now - lastTestAt > 0.5) then
        showTestNotification()
        lastTestAt = now
    end
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
    end, prettyUILibrary, showTestNotification)
    if ok then
        refreshSettings, destroySettings = result, destroy
    else
        print("[supply-check] Settings creation failed: " .. tostring(result))
    end
end)
Event.MiniMenuEntrySelected.Subscribe("supplyCheck.presetTest", function(event)
    local entry = event.entry
    local component = entry and entry.componentData and entry.componentData.component
    if component and not component.isRestricted and component.interfaceID == 517 then
        print("[supply-check] Bank action: verb=" .. tostring(entry.verbText)
            .. " static=" .. tostring(component.staticID)
            .. " dynamic=" .. tostring(component.dynamicID))
    elseif entry and type(entry.verbText) == "string"
        and entry.verbText:lower():find("preset", 1, true) then
        print("[supply-check] Preset action: verb=" .. entry.verbText)
    end
    if presetTest.isLoad(event.entry) then
        showTestNotification()
        lastTestAt = now
    end
end)
Event.VarTransmit.Subscribe("supplyCheck.presetProbe", function(event)
    local variable = event.var
    if variable and variable.typeName == "VarPlayer" and
        (variable.id == 9932 or variable.id == 4331 or variable.id == 4338
            or variable.id == -22180 or variable.id == -22184 or variable.id == -29486) then
        print("[supply-check] Preset var transmit: id=" .. tostring(variable.id)
            .. " old=" .. tostring(event.oldValue) .. " new=" .. tostring(event.newValue))
    end
end)
Event.GameStateChanged.Subscribe("supplyCheck.state", function(event)
    canRead = event.newState == 30 -- GameState.GAME
    if not canRead then
        quiverDiagnostic.reset()
        monitor.reset()
        popup.clear()
        presetWatcher.reset()
        bankCloseTest.reset()
        lastTestAt = nil
    end
    refresh()
end)

function PluginShutdown()
    refreshSettings = nil
    if destroySettings then pcall(destroySettings); destroySettings = nil end
    popup.clear()
    Event.ServerLogic.Unsubscribe("supplyCheck.refresh")
    Event.Logic.Unsubscribe("supplyCheck.clock")
    Event.SettingsLayerReady.Unsubscribe("supplyCheck.settings")
    Event.MiniMenuEntrySelected.Unsubscribe("supplyCheck.presetTest")
    Event.VarTransmit.Unsubscribe("supplyCheck.presetProbe")
    Event.GameStateChanged.Unsubscribe("supplyCheck.state")
end
