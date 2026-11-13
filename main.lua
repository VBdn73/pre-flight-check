local reader = require("supplies/inventory-reader")
local warningSettings = require("warnings/settings")
local settingsView = require("warnings/settings-view")
local warningMonitor = require("warnings/monitor")
local popup = require("warnings/popup")
local ribbon = require("warnings/ribbon")
local presetTrigger = require("bank/preset-trigger")
local presetMessages = require("bank/preset-messages")
local portalTrigger = require("warnings/portal-trigger")
local checkButton = require("warnings/check-button")
local sigils = require("supplies/sigils")
local constants = require("constants")
local presetAlerts = require("bank/preset-alerts")
local supplyCount = require("supplies/count")
local manualCheckDeadline
local portalCapture
local portalCheckDeadline
local bankState = require("bank/state").new()
local prettyUILibrary = prettyui
local rules = warningSettings.load()
local monitor = warningMonitor.new(rules)
local refreshSettings, destroySettings
local canRead = true
local now
local checkAfter, checkDeadline
local anticipatedCloseUntil
local presetSettleDelay = constants.SERVER_TICK_SECONDS
local chatAlerts, chatUntil, chatReady = {}, nil, nil

local function clearPresetChat()
    chatAlerts, chatUntil, chatReady = {}, nil, nil
end

local function beginPresetChat()
    if canRead and now and rules.checkOnPreset and rules.presetChatNotifications
        and Plugin.HasPermission(PluginPermissions.chatAccess) then
        chatAlerts, chatUntil, chatReady = {}, now + constants.PRESET_CHAT_WINDOW_SECONDS, nil
    end
end

local function showAlerts(alerts)
    ribbon.record(alerts, now)
    if #alerts == 0 then
        popup.clear()
        return
    end
    popup.show(alerts, now, rules.popupDuration, prettyUILibrary, rules.popupRows, rules)
end

local function capturePortal(event)
    if not rules.checkOnPortalEntry or not canRead or not now then
        portalCapture = nil
        return
    end
    -- Warning dialogs use interface actions for Yes/No and their checkbox.
    -- Keep the original deadline: clicking a dialog is not evidence of travel.
    if portalCapture and event.entry and event.entry.componentData then return end
    portalCapture = nil -- Another world action cancels the previous attempt.
    portalCapture = portalTrigger.begin(event.entry, now, portalTrigger.position())
end

-- Wait for server updates following the action before taking a fresh snapshot.
local function scheduleCheck(delay)
    if not canRead or not now then return end
    checkAfter, checkDeadline = now + delay, now + constants.CHECK_RETRY_SECONDS
end

local function anticipateClose(alwaysCheck, delay)
    -- Avoid scheduling a second check when an anticipated bank close is observed.
    if alwaysCheck or not anticipatedCloseUntil then scheduleCheck(delay or 0) end
    anticipatedCloseUntil = now + constants.BANK_CLOSE_WINDOW_SECONDS
end

local function refresh()
    if not rules.checkOnPreset or not rules.presetChatNotifications then
        clearPresetChat()
    end
    local snapshot = canRead and reader.read() or {
        backpack = { available = false }, equipment = { available = false },
    }
    if not supplyCount.available(snapshot) then popup.clear() end
    if not canRead or not now or not checkAfter or now < checkAfter then return end
    if chatReady and now < chatReady then return end
    -- Retry unavailable snapshots until the deadline instead of treating them as empty.
    if not supplyCount.available(snapshot) then
        if now >= checkDeadline then checkAfter, checkDeadline = nil, nil end
        return
    end
    checkAfter, checkDeadline = nil, nil
    local alerts = monitor.update(snapshot)
    presetAlerts.merge(alerts, chatAlerts)
    chatAlerts, chatReady = {}, nil
    showAlerts(alerts)
end

Event.ServerLogic.Subscribe("supplyCheck.refresh", function()
    refresh()
    if manualCheckDeadline and canRead and now then
        local snapshot = reader.read()
        if supplyCount.available(snapshot) then
            manualCheckDeadline = nil
            showAlerts(monitor.update(snapshot))
        elseif now >= manualCheckDeadline then
            manualCheckDeadline = nil
        end
    end
    if not rules.checkOnPortalEntry then portalCheckDeadline = nil end
    if not portalCheckDeadline or not canRead or not now then return end
    if now >= portalCheckDeadline then portalCheckDeadline = nil; return end
    local snapshot = reader.read()
    if not supplyCount.available(snapshot) then return end
    portalCheckDeadline = nil
    -- Independent of preset chat collection and its settle timer.
    showAlerts(monitor.update(snapshot))
end)
Event.Logic.Subscribe("supplyCheck.clock", function(event)
    now = event.logicTick / constants.LOGIC_TICKS_PER_SECOND
    sigils.setTick(canRead and event.logicTick or nil)
    checkButton.update(rules.showCheckButton and canRead, function()
        if not canRead or not now or not rules.showCheckButton then return end
        -- Manual checks never consume preset chat or depend on automatic triggers.
        local snapshot = reader.read()
        if supplyCount.available(snapshot) then
            manualCheckDeadline = nil
            showAlerts(monitor.update(snapshot))
        else
            manualCheckDeadline = now + constants.CHECK_RETRY_SECONDS
        end
    end, rules.lockCheckButton)
    if not rules.checkOnPortalEntry then portalCapture = nil; portalCheckDeadline = nil end
    if portalCapture then
        local capture, arrived = portalCapture, false
        portalCapture, arrived = portalTrigger.advance(capture, now,
            canRead and portalTrigger.position() or nil)
        if arrived then
            if rules.checkOnPortalEntry then portalCheckDeadline = now + constants.CHECK_RETRY_SECONDS end
        end
    end
    if not rules.checkOnPreset or not rules.presetChatNotifications then
        clearPresetChat()
    end
    if chatReady and now >= chatReady then
        refresh()
        if chatReady then
            if #chatAlerts > 0 then showAlerts(chatAlerts) end
            chatAlerts, chatReady = {}, nil
        end
    end
    if chatUntil and now >= chatUntil then chatUntil = nil end
    popup.update(now)
    ribbon.update()
    if anticipatedCloseUntil and now >= anticipatedCloseUntil then anticipatedCloseUntil = nil end
    if canRead and bankState.update() then
        if rules.checkOnBankClose and not anticipatedCloseUntil then scheduleCheck(0) end
        anticipatedCloseUntil = nil
    end
    if refreshSettings then
        local ok, err = pcall(refreshSettings)
        if not ok then
            print("[pre-flight-check] Settings refresh failed: " .. tostring(err))
            refreshSettings = nil
            if destroySettings then pcall(destroySettings); destroySettings = nil end
        end
    end
end)
Event.ChatMessage.Subscribe("supplyCheck.presetMessages", function(event)
    if not canRead or not now or not rules.checkOnPreset or not rules.presetChatNotifications
        or not Plugin.HasPermission(PluginPermissions.chatAccess) then return end
    local kind, alert = presetMessages.parse(event)
    if kind == "start" then
        chatAlerts, chatUntil, chatReady = {}, now + constants.PRESET_CHAT_WINDOW_SECONDS, now + presetSettleDelay
    elseif (kind == "issue" or (kind == "charge" and rules.itemDurability))
        and (not alert.setting or rules[alert.setting]) and chatUntil and now < chatUntil then
        chatAlerts[#chatAlerts + 1] = alert
        chatReady = now + presetSettleDelay
    end
end)
Event.KeyDown.Subscribe("supplyCheck.presetShortcut", function(event)
    if not canRead or not now or not bankState.isMainPanelOpen() then return end
    if event.gameKey == constants.KEY_ESCAPE and not event.isRepeat and rules.checkOnBankClose then
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
        modifiers = (ctrl and constants.MODIFIER.CONTROL or 0)
            + (shift and constants.MODIFIER.SHIFT or 0) + (alt and constants.MODIFIER.ALT or 0)
    end
    if presetTrigger.isShortcut(event, modifiers) then
        beginPresetChat()
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
        if not rules.checkOnPreset or not rules.presetChatNotifications then
            clearPresetChat()
        end
    end, prettyUILibrary)
    if ok then
        refreshSettings, destroySettings = result, destroy
    else
        print("[pre-flight-check] Settings creation failed: " .. tostring(result))
    end
end)
Event.ContentLayerReady.Subscribe("supplyCheck.content", function(event)
    local ok, err = pcall(ribbon.open, event.component, prettyUILibrary, rules)
    if not ok then print("[pre-flight-check] Ribbon creation failed: " .. tostring(err)) end
end)
Event.MiniMenuEntrySelected.Subscribe("supplyCheck.preset", function(event)
    capturePortal(event)
    if not presetTrigger.isLoad(event.entry) then return end
    beginPresetChat()
    if rules.checkOnBankClose and canRead and now and bankState.isMainPanelOpen() then
        bankState.markOpen()
        anticipateClose(true, presetSettleDelay)
    elseif rules.checkOnPreset then
        scheduleCheck(presetSettleDelay)
    end
end)
Event.GameStateChanged.Subscribe("supplyCheck.state", function(event)
    canRead = event.newState == constants.GAME_STATE.PLAYING
    -- Preserve the approach across LOADING, but never across logout/login.
    if not canRead and event.newState ~= constants.GAME_STATE.LOADING then
        portalCapture, portalCheckDeadline = nil, nil
    end
    if not canRead then
        sigils.setTick(nil)
        checkButton.close()
        manualCheckDeadline = nil
        popup.clear()
        bankState.reset()
        checkAfter, checkDeadline = nil, nil
        anticipatedCloseUntil = nil
        clearPresetChat()
    end
    refresh()
end)

function PluginShutdown()
    checkButton.close()
    manualCheckDeadline = nil
    portalCapture = nil
    portalCheckDeadline = nil
    refreshSettings = nil
    if destroySettings then pcall(destroySettings); destroySettings = nil end
    popup.clear()
    ribbon.close()
    Event.ServerLogic.Unsubscribe("supplyCheck.refresh")
    Event.Logic.Unsubscribe("supplyCheck.clock")
    Event.KeyDown.Unsubscribe("supplyCheck.presetShortcut")
    Event.ChatMessage.Unsubscribe("supplyCheck.presetMessages")
    Event.SettingsLayerReady.Unsubscribe("supplyCheck.settings")
    Event.ContentLayerReady.Unsubscribe("supplyCheck.content")
    Event.MiniMenuEntrySelected.Unsubscribe("supplyCheck.preset")
    Event.GameStateChanged.Unsubscribe("supplyCheck.state")
end
