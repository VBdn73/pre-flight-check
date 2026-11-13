-- Mock client controls and PrettyUI widgets used by the settings view.
local controls = {}
local function control(kind, parent)
    local c = { kind = kind, parent = parent, hooks = {} }
    function c:SetPos(x, y, xa, ya) self.x, self.y, self.xAnchor, self.yAnchor = x, y, xa, ya end
    function c:SetSize(w, h, wa, ha) self.width, self.height, self.widthAnchor, self.heightAnchor = w, h, wa, ha end
    function c:Subscribe(hook, id, callback)
        if type(id) == "function" then callback = id end
        self.hooks[hook] = callback
    end
    function c:Setup() end
    function c:Destroy() self.destroyed = true end
    function c:SetAssociatedObject(itemId, ...)
        assert(select("#", ...) == 0, "SetAssociatedObject takes one argument")
        self.itemId = itemId
    end
    if kind == "input" then
        setmetatable(c, {
            __index = function(t, key) if key == "content" then return rawget(t, "_content") end end,
            __newindex = function(t, key, value)
                if key == "content" then
                    rawset(t, "_content", value)
                    if t.simulateProgrammaticChange and t.hooks.change then
                        t.hooks.change(t, ui.InputFieldActionResult.CONTENT_CHANGE)
                    end
                else rawset(t, key, value) end
            end,
        })
    end
    controls[#controls + 1] = c
    return c
end
ui = { Text = { new = function(parent) return control("text", parent) end },
    Layer = { new = function(parent) return control("layer", parent) end },
    Sprite = { new = function(parent) return control("sprite", parent) end },
    Rectangle = { new = function(parent) return control("rectangle", parent) end },
    Check = { new = function(parent) return control("check", parent) end },
    Button = { new = function(parent) return control("button", parent) end },
    InputField = { new = function(parent) return control("input", parent) end },
    Hook = { ONBUTTONPRESSED = "press", ONCLICK = "click", ONSCROLLWHEEL = "wheel", ONCONTENTCHANGED = "change", ONMOUSEOVER = "over" },
    InputFieldActionResult = { SUBMIT = 1, SUBMIT_ON_FOCUS_LOSS = 2, CONTENT_CHANGE = 3 },
    TextContentVisibilityMode = { VISIBLE = 1 }, InputFieldFilterMode = { NUMBERS_AS_TEXT = 1 },
    AlignMode = { CENTRE = 1 } }
id = { Font = { MUSEO_SANS_11PT_REGULAR = 1 }, StyleSheet = {
    BUTTON_DEFAULT = 1, INPUT_DEFAULT = 2, CHECKBOX_DEFAULT_LEFT_ALIGNED = 3, CHECKBOX_DEFAULT = 4 } }
local tabs
local prettyui = { Tooltip = { attach = function(target, _, value)
    target.tooltip = value
    local tip = { options = value, width = 240, height = 60, Hide = function() end, Destroy = function() end }
    target.attachment = tip
    return tip
end }, CheckboxButton = { new = function(parent, entries, options)
    local root = control("checkbox", parent)
    root:SetSize(options.width, 25)
    local item = { label = {}, selected = entries[1].selected }
    local result = { root = root, items = { item } }
    function result:SetSelected(key, selected, notify)
        assert(key == entries[1].value)
        item.selected = selected
        if notify then options.onChange(self, key, item, selected) end
    end
    function result:SetDisabled(disabled) self.disabled = disabled end
    root.hooks.press = function()
        if not result.disabled then result:SetSelected(entries[1].value, not item.selected, true) end
    end
    function result:Destroy() self.destroyed = true end
    root.checkbox = result
    item.label.content = entries[1].text
    return result
end }, SpriteButton = { new = function(parent, sprite, action, options)
    local root = control("iconButton", parent)
    root:SetPos(options.x, options.y); root:SetSize(options.size, options.size)
    root.spriteName, root.tooltip = sprite, options.tooltip
    local result = { root = root, disabled = options.disabled }
    root.spriteButton = result
    root.hooks.press = function()
        if options.toggleable then result.disabled = not result.disabled end
        action(result, not result.disabled)
    end
    function result:Destroy() self.destroyed = true end
    function result:SetDisabled(disabled) self.disabled = disabled end
    return result
end }, Tabs = { new = function(host, entries, options)
    tabs = { entries = entries, options = options, pages = {}, active = 1 }
    for i = 1, 6 do
        local page = { content = {}, scrollY = 0, contentHeight = 0, sections = {} }
        page._scroll = { Refresh = function()
            page.height = math.max(1, host.height - 42)
            page.scrollbarVisible = page.contentHeight > page.height
        end }
        function page:SetContentHeight(h) self.contentHeight = h; self._scroll:Refresh() end
        function page:ScrollBy(delta) self.scrollY = math.max(0, math.min(self.contentHeight - self.height, self.scrollY + delta)) end
        function page:reflow()
            local y = options.contentLayout.startY
            if self.flowText and self.flowTextBeforeSections then
                self.flowText.y = y
                y = y + self.flowText.height + 2
            end
            for _, section in ipairs(self.sections) do
                y = y + (section.marginTop or 0)
                section.root.y = y
                y = y + 20 + (section.expanded and 4 + section.contentHeight or 0) + 8
            end
            if self.flowText and not self.flowTextBeforeSections then
                self.flowText.y = y
                y = y + self.flowText.height + 2
            end
            self:SetContentHeight(y + 6)
            self.scrollY = math.min(self.scrollY, math.max(0, self.contentHeight - self.height))
        end
        function page:AddCollapseButton(name, opts)
            local section = { name = name, expanded = opts.expanded, root = {}, marginTop = opts.marginTop,
                content = { x = opts.indent or 20, y = 24 }, contentHeight = 0 }
            function section:_SetContentHeight(h) self.contentHeight = h; page:reflow() end
            function section:SetExpanded(value)
                self.expanded = value; page:reflow(); opts.onToggle(self, value)
            end
            self.sections[#self.sections + 1] = section
            self:reflow()
            return section
        end
        function page:AddText(opts)
            self.flowText = control("flowText", self.content)
            self.flowTextBeforeSections = #self.sections == 0
            self.flowText:SetSize(0, opts.height, 1, 0)
            self:reflow()
            return self.flowText
        end
        tabs.pages[i] = page
    end
    function tabs:GetPage(i) return self.pages[i] end
    function tabs:GetActiveIndex() return self.active end
    function tabs:Destroy() self.destroyed = true end
    return tabs
end } }
local saved
PersistentDB = { GetStructuredData = function() return saved end,
    SetStructuredData = function(_, _, data) saved = data; return true end }
local rules = require("warnings/settings").load()
local host = { width = 400, height = 600, xyGlobal = { x = 100, y = 100 } }
local changes = 0
local pickers = {}
prettyui.ColourPicker = { new = function(parent, options)
    local root = control("colourPicker", parent)
    root:SetPos(options.x, options.y); root:SetSize(options.width, options.height)
    local picker = { root = root, value = options.value, options = options,
        swatch = control("swatch", root), swatchFrame = control("swatchFrame", root) }
    function picker:_PickerWindowBounds() return 0, 0, 180, 280 end
    function picker:Open() self.pickerWindow = { titleDrag = {} }; return true end
    function picker:SetValue(value, notify)
        self.value = value
        if notify ~= false then options.onChange(self, value) end
    end
    function picker:Close() self.closed = true end
    function picker:Destroy() self.destroyed = true end
    pickers[#pickers + 1] = picker
    return picker
end }
-- Tab layout, sections, and accordion behavior.
local refresh, destroy = require("warnings/settings-view").build(host, rules, function() changes = changes + 1 end, prettyui)
local general, magic, necro, ranged, melee, misc = table.unpack(tabs.pages)
assert(tabs.entries[1].text == "General" and tabs.entries[5].text == "Melee")
assert(tabs.options.contentLayout.startY == 80)
assert(magic.sections[1].root.y == 80 and necro.flowText.y == 80)
assert(necro.sections[1].root.y > necro.flowText.y)
assert(#melee.sections == 0 and melee.flowText.y == 80 and misc.sections[1].root.y == 80)
assert(ranged.sections[1].root.y == 80)
assert(ranged.flowText.y > ranged.sections[4].root.y)
assert(magic.sections[1].name == "Elemental" and magic.sections[2].name == "Catalytic")
assert(necro.sections[1].name == "Necrotic Runes" and ranged.sections[1].name == "Elder God Arrows")
assert(ranged.sections[2].name == "Special Arrows" and ranged.sections[3].name == "Enchanted Bakriminel Bolts")
assert(#necro.sections == 1 and #melee.sections == 0)
assert(tabs.entries[6].text == "Misc" and misc.sections[1].name == "Bombs")
assert(misc.sections[2].name == "Invention")
assert(misc.sections[3].name == "God Books" and #misc.sections == 3)
assert(misc.flowText.y > misc.sections[3].root.y and misc.flowText.height == 440)
local miscRows
for _, c in ipairs(controls) do
    if c.kind == "layer" and c.parent == misc.content then miscRows = c; break end
end
assert(miscRows and miscRows.y == misc.flowText.y)
magic.sections[1]:SetExpanded(true)
magic.sections[2]:SetExpanded(true)
assert(not magic.sections[1].expanded and magic.sections[2].expanded)
magic.sections[2]:SetExpanded(false)
necro.sections[1]:SetExpanded(true)
necro.sections[1]:SetExpanded(false)
local function find(parent, kind, x, y)
    for _, c in ipairs(controls) do
        if not c.destroyed and c.parent == parent and c.kind == kind and c.x == x and c.y == y then return c end
    end
    error("control not found: " .. kind .. " " .. x .. "," .. y)
end
-- Miscellaneous warnings, permissions, and persistence.
local style = magic.content
local sign = find(miscRows, "check", -30, 7)
local death = find(miscRows, "check", -30, 47)
local durability = find(miscRows, "check", -30, 87)
PluginPermissions = { chatAccess = 1 }
local permission = false
Plugin = { HasPermission = function() return permission end }
assert(not rules.itemDurability)
durability.hooks.press()
assert(not rules.itemDurability)
rules.presetChatNotifications = true
durability.hooks.press()
assert(not rules.itemDurability)
permission = true
durability.hooks.press()
assert(rules.itemDurability and saved.itemDurability and require("warnings/settings").load().itemDurability)
durability.hooks.press()
assert(not rules.itemDurability)
rules.presetChatNotifications = false
assert(find(miscRows, "text", 48, 43).content == "Death reclaim")
assert(death.value and rules.deathReclaim)
death.hooks.press()
assert(not rules.deathReclaim and not saved.deathReclaim)
assert(not require("warnings/settings").load().deathReclaim)
death.hooks.press()
assert(rules.deathReclaim and saved.deathReclaim)
assert(find(miscRows, "text", 48, 283).content == "Ushabti (empty)")
assert(find(miscRows, "sprite", 8, 283).itemId == 40407)
local flask = find(miscRows, "text", 48, 323)
assert(flask.content == "Blessed flask: warning unavailable")
assert(find(miscRows, "sprite", 8, 323).itemId == 48680)
local grace = find(miscRows, "text", 48, 363)
assert(grace.content == "Grace of the elves: warning unavailable")
assert(find(miscRows, "sprite", 8, 363).itemId == 44548)
assert(find(miscRows, "text", 48, 403).content == "Scrimshaw: warning unavailable")
assert(find(miscRows, "sprite", 8, 403).itemId == 26295)
assert(find(miscRows, "text", 48, 83).content == "Item durability")
assert(find(miscRows, "sprite", 8, 83).itemId == 2347)
assert(miscRows.height == 440 and misc.sections[3].contentHeight == 840)
assert(find(miscRows, "text", 48, 123).content == "Excalibur cooldown")
assert(find(miscRows, "sprite", 8, 123).itemId == 14632)
local excalibur = find(miscRows, "check", -30, 127)
assert(excalibur.value and rules.excalibur)
excalibur.hooks.press()
assert(not rules.excalibur and not saved.excalibur)
assert(not require("warnings/settings").load().excalibur)
excalibur.hooks.press()
assert(rules.excalibur and saved.excalibur)
assert(find(miscRows, "text", 48, 163).content == "Powerburst cooldown")
assert(find(miscRows, "sprite", 8, 163).itemId == 49095)
local powerburst = find(miscRows, "check", -30, 167)
assert(powerburst.value and rules.powerburst)
powerburst.hooks.press()
assert(not rules.powerburst and not saved.powerburst)
assert(not require("warnings/settings").load().powerburst)
powerburst.hooks.press()
assert(rules.powerburst and saved.powerburst)
assert(find(miscRows, "sprite", 8, 203).itemId == 22370)
assert(find(miscRows, "sprite", 8, 243).itemId == 22371)
assert(find(misc.sections[3].content, "text", 8, 8).content
    == "Only equipped books are checked; backpack timers are unavailable.")
for i, name in ipairs({ "Scripture of Jas", "Scripture of Wen", "Scripture of Bik",
    "Scripture of Ful", "Scripture of Amascut", "Scripture of Elidinis" }) do
    assert(find(misc.sections[3].content, "text", 48, i * 40 + 3).content == name)
end
assert(find(misc.sections[3].content, "text", 48, 283).content == "Erethdor's grimoire")
assert(find(misc.sections[3].content, "text", 48, 323).content == "Chaotic grimoire")
local fulLow = find(misc.sections[3].content, "input", -171, 165)
local fulCritical = find(misc.sections[3].content, "input", -104, 165)
assert(fulLow.content == "60" and fulCritical.content == "30")
fulLow.content = "1441"
fulLow.hooks.change(fulLow, ui.InputFieldActionResult.SUBMIT)
assert(saved == nil or not saved["52494"] or saved["52494"].low == 60)
fulLow.content = "120"
fulLow.hooks.change(fulLow, ui.InputFieldActionResult.SUBMIT)
assert(saved["52494"].low == 120 and saved["52494"].critical == 30)
for _, rule in ipairs(rules) do assert(rule.itemId ~= 48680 and rule.itemId ~= 44548) end
local signBackground = find(miscRows, "rectangle", 1, 1)
assert(rules.signOfLife)
assert(signBackground.rgba == 0x23412DE8 and sign.value)
sign.hooks.press()
assert(not rules.signOfLife and not saved.signOfLife)
assert(signBackground.rgba == 0x492626E8 and not sign.value)
assert(not require("warnings/settings").load().signOfLife)
sign.hooks.press()
assert(signBackground.rgba == 0x23412DE8 and sign.value)
-- General settings, validation, and failed saves.
local preset = find(general.content, "checkbox", 10, 40)
local presetChat = find(general.content, "checkbox", 25, 75)
assert(not rules.presetChatNotifications)
assert(presetChat.checkbox.items[1].label.content == "Preset chat notifications" and not presetChat.checkbox.disabled)
presetChat.hooks.press()
assert(rules.presetChatNotifications and saved.presetChatNotifications)
preset.hooks.press()
assert(not rules.checkOnPreset and not rules.presetChatNotifications and not saved.presetChatNotifications)
assert(presetChat.checkbox.disabled and presetChat.checkbox.items[1].label.content == "Preset chat notifications")
presetChat.hooks.press()
assert(not rules.presetChatNotifications and not presetChat.checkbox.items[1].selected)
preset.hooks.press()
assert(rules.checkOnPreset and not rules.presetChatNotifications)
assert(not presetChat.checkbox.disabled)
local bank = find(general.content, "checkbox", 10, 110)
local duration = find(general.content, "input", 205, 150)
local durationStatus = find(general.content, "text", 274, 150)
local rows = find(general.content, "input", 205, 185)
local rowsStatus = find(general.content, "text", 274, 185)
local lowColour, criticalColour = table.unpack(pickers)
assert(lowColour.root == find(general.content, "colourPicker", 205, 220))
assert(criticalColour.root == find(general.content, "colourPicker", 205, 255))
assert(lowColour.value == 0xFF9429FF and criticalColour.value == 0xF24033FF)
assert(lowColour.swatch.width == 56 and lowColour.swatch.height == 17)
assert(criticalColour.swatchFrame.width == 58 and criticalColour.swatchFrame.height == 19)
lowColour.root.xyGlobal = { x = 305, y = 285 }
assert(lowColour:Open())
assert(lowColour.options.windowX == 17 and lowColour.options.windowY == 185)
assert(lowColour.pickerWindow.titleDrag.hidden)
criticalColour.root.xyGlobal = { x = 110, y = 320 }
assert(criticalColour:Open())
assert(criticalColour.options.windowX == 82 and criticalColour.options.windowY == 220)
assert(criticalColour.pickerWindow.titleDrag.hidden)
lowColour:SetValue(0x123456FF)
assert(rules.lowColour == "#123456" and saved.lowColour == "#123456")
assert(require("warnings/settings").load().lowColour == "#123456")
PersistentDB.SetStructuredData = function() return false end
criticalColour:SetValue(0xABCDEFFF)
assert(rules.criticalColour == nil and find(general.content, "text", 274, 255).content == "Save failed")
assert(criticalColour.value == 0xF24033FF)
PersistentDB.SetStructuredData = function(_, _, data) saved = data; return true end
criticalColour:SetValue(0xABCDEFFF)
assert(saved.criticalColour == "#ABCDEF")
assert(rows.content == "8")
rows.content = "10"
rows.hooks.change(rows, ui.InputFieldActionResult.SUBMIT)
assert(rules.popupRows == 10 and saved.popupRows == 10)
rows.content = "21"
rows.hooks.change(rows, ui.InputFieldActionResult.SUBMIT)
assert(rules.popupRows == 10 and rowsStatus.content ~= "")
rows.content = "5"
PersistentDB.SetStructuredData = function() return false end
rows.hooks.change(rows, ui.InputFieldActionResult.SUBMIT_ON_FOCUS_LOSS)
assert(rules.popupRows == 10 and rowsStatus.content == "Save failed")
PersistentDB.SetStructuredData = function(_, _, data) saved = data; return true end
assert(duration.content == "4")
duration.content = "15"
duration.hooks.change(duration, ui.InputFieldActionResult.SUBMIT)
assert(rules.popupDuration == 15 and saved.popupDuration == 15)
duration.content = "0"
duration.hooks.change(duration, ui.InputFieldActionResult.SUBMIT)
assert(rules.popupDuration == 15 and durationStatus.content ~= "")
duration.content = "20"
PersistentDB.SetStructuredData = function() return false end
duration.hooks.change(duration, ui.InputFieldActionResult.SUBMIT_ON_FOCUS_LOSS)
assert(rules.popupDuration == 15 and durationStatus.content == "Save failed")
PersistentDB.SetStructuredData = function(_, _, data) saved = data; return true end
assert(preset.checkbox.items[1].label.content == "Check on preset load")
assert(bank.checkbox.items[1].label.content == "Check on bank close")
assert(preset.checkbox.items[1].selected and not bank.checkbox.items[1].selected)
bank.hooks.press()
assert(saved.checkOnPreset and saved.checkOnBankClose)
assert(preset.checkbox.items[1].selected and bank.checkbox.items[1].selected)
bank.hooks.press()
refresh()
assert(not bank.checkbox.items[1].selected and not rules.checkOnBankClose)
bank.hooks.press()
PersistentDB.SetStructuredData = function() return false end
preset.hooks.press()
assert(preset.checkbox.items[1].selected and rules.checkOnPreset, "failed save restores the checkbox")
PersistentDB.SetStructuredData = function(_, _, data) saved = data; return true end
-- Reopening restores saved settings and displays style defaults.
destroy()
assert(preset.checkbox.destroyed and bank.checkbox.destroyed)
assert(lowColour.destroyed and criticalColour.destroyed)
controls = {}
rules = require("warnings/settings").load()
assert(rules.checkOnPreset and rules.checkOnBankClose, "checkbox choices survive a settings reload")
assert(rules.popupDuration == 15)
assert(rules.popupRows == 10)
refresh, destroy = require("warnings/settings-view").build(host, rules, function() changes = changes + 1 end, prettyui)
general, magic, necro, ranged, melee, misc = table.unpack(tabs.pages)
style = magic.content
preset = find(general.content, "checkbox", 10, 40)
bank = find(general.content, "checkbox", 10, 110)
assert(preset.checkbox.items[1].selected and bank.checkbox.items[1].selected, "reopening settings shows enabled checks")
tabs.active = 2
refresh()
assert(not find(style, "input", 165, 38).hidden)
local defaultLabel = find(style, "text", 10, 38)
assert(defaultLabel.content == "Magic defaults" and defaultLabel.height == 25
    and defaultLabel.alignVertical == ui.AlignMode.CENTRE)
for _, page in ipairs({ magic, necro, ranged, melee }) do
    assert(find(page.content, "input", 165, 38).tooltip.text:find("Low"))
    assert(find(page.content, "input", 232, 38).tooltip.text:find("Critical"))
    for _, c in ipairs(controls) do
        assert(not (c.parent == page.content and c.content == "Low / critical below"))
    end
end
find(style, "input", 165, 38).content = "5000"
find(style, "input", 165, 38).hooks.change(nil, ui.InputFieldActionResult.CONTENT_CHANGE)
assert(rules.styles.Magic.low ~= 5000)
find(style, "input", 165, 38).hooks.change(nil, ui.InputFieldActionResult.SUBMIT_ON_FOCUS_LOSS)
assert(saved.styles.Magic.low == 5000 and rules.styles.Magic.low == 5000)
assert(find(style, "text", 302, 38).content == "", "successful saves do not display a status message")
-- Custom thresholds, tooltip placement, and row clipping.
host.height = 600
magic.sections[1]:SetExpanded(true)
refresh()
local fire = magic.sections[1].content
local override = find(fire, "button", -251, 5)
local customLow = find(fire, "input", -171, 5)
local customCritical = find(fire, "input", -104, 5)
local mode = find(fire, "text", -251, 5)
assert(override.width == 75 and mode.width == 75 and mode.alignHorizontal == ui.AlignMode.CENTRE
    and mode.alignVertical == ui.AlignMode.CENTRE)
assert(override.xAnchor == 1 and customLow.xAnchor == 1 and customCritical.xAnchor == 1)
assert(override.tooltip.placement == "above" and override.tooltip.text:find("style thresholds"))
assert(customLow.tooltip.text:find("Low") and customCritical.tooltip.text:find("Critical"))
assert(customLow.tooltip.placement == "above" and customCritical.tooltip.placement == "above")
assert(not customLow.tooltip.constrainToParent and not override.tooltip.constrainToParent)
customLow.x = 280 -- The real client exposes resolved coordinates for anchored controls.
customLow.hooks.over()
assert(customLow.tooltip.x == 104 and customLow.tooltip.y == -61)
customLow.attachment.context = { active = true, position = function() return 350, 180 end }
customLow.hooks.over()
assert(customLow.tooltip.x == 174 and customLow.tooltip.y == 114)
customLow.attachment.context = nil
customLow.x = -171
override.x = 200
override.hooks.over()
assert(override.tooltip.x == 35 and override.tooltip.y == -61)
override.x = -251
assert(find(fire, "text", 48, 3).widthAnchor == 1)
assert(mode.content == "Defaults" and not customLow.hidden and not customLow.enabled and customLow.clickthrough)
assert(customLow.content == "1000")
local frame = find(fire, "rectangle", 0, 0)
local background = find(fire, "rectangle", 1, 1)
local switch = find(fire, "check", -30, 7)
assert(switch.xAnchor == 1 and switch.stylesheetID == id.StyleSheet.CHECKBOX_DEFAULT)
assert(switch.tooltip.text:find("Enable or disable") and switch.tooltip.placement == "above" and switch.value)
assert(not background.hooks.click)
for _, c in ipairs(controls) do
    assert(not (c.parent == fire and c.kind == "rectangle" and c.x == -171 and c.y == 5),
        "no hover overlay should block the input")
end
assert(frame and background and frame.height == 36 and background.height == 34)
 assert(fire.x == 0 and frame.x == 0 and frame.width == 0 and background.width == -2)
local fireIcon = find(fire, "sprite", 8, 3)
local itemLabel = find(fire, "text", 48, 3)
assert(itemLabel.y == fireIcon.y and itemLabel.height == fireIcon.height
    and itemLabel.alignVertical == ui.AlignMode.CENTRE)
host.height = magic.sections[1].root.y + fire.y + 15 + 42
refresh()
assert(not fireIcon.hidden, "partially visible icon at the bottom remains visible")
for _, c in ipairs({ itemLabel, override, mode, customLow, customCritical, switch }) do
    assert(not c.hidden, "partially visible row controls at the bottom remain visible")
end
host.height = 600
refresh()
 magic.scrollY = magic.sections[1].root.y + fire.y + 20
 refresh()
assert(not fireIcon.hidden, "partially visible icon at the top remains visible")
for _, c in ipairs({ itemLabel, override, mode, customLow, customCritical, switch }) do
    assert(not c.hidden, "partially visible row controls at the top remain visible")
end
 assert(not frame.hidden and frame.y == 20 and frame.height == 16)
 assert(not background.hidden and background.y == 20 and background.height == 15)
magic.scrollY = magic.sections[1].root.y + fire.y + fireIcon.y + fireIcon.height
refresh()
assert(fireIcon.hidden, "icon completely above the viewport is hidden")
for _, c in ipairs({ itemLabel, override, mode, customLow, customCritical, switch }) do
    assert(c.hidden, "row controls completely above the viewport are hidden")
end
magic.scrollY = 0
refresh()
assert(frame.y == 0 and frame.height == 36 and background.y == 1 and background.height == 34)
override.hooks.press()
assert(mode.content == "Custom" and customLow.content == "1000" and customLow.enabled)
customLow.content = "5500"
customLow.hooks.change(nil, ui.InputFieldActionResult.CONTENT_CHANGE)
assert(mode.content == "Custom" and rules.styles.Magic.low == 5000)
customLow.hooks.change(nil, ui.InputFieldActionResult.SUBMIT_ON_FOCUS_LOSS)
assert(saved["554"].custom and saved["554"].low == 5500)
override.hooks.press()
assert(mode.content == "Defaults" and customLow.content == "5500" and not customLow.enabled)
assert(require("warnings/settings").effective(rules, rules[4]).low == 5000)
override.hooks.press()
refresh()
assert(not customLow.hidden and customLow.enabled and mode.content == "Custom")
assert(saved["554"].custom)
customLow.content = "7000"
customLow.hooks.change(nil, ui.InputFieldActionResult.SUBMIT_ON_FOCUS_LOSS)
assert(saved["554"].custom and saved["554"].low == 7000)
customLow.content = "1"
customLow.hooks.change(nil, ui.InputFieldActionResult.SUBMIT_ON_FOCUS_LOSS)
assert(mode.content == "Invalid" and saved["554"].low == 7000)
customLow.content = "8000"
PersistentDB.SetStructuredData = function() return false end
customLow.hooks.change(nil, ui.InputFieldActionResult.SUBMIT)
assert(mode.content == "Failed" and rules[4].low == 7000)
override.hooks.press()
assert(rules[4].custom)
PersistentDB.SetStructuredData = function(_, _, data) saved = data; return true end
customLow.content = "7000"
customLow.hooks.change(nil, ui.InputFieldActionResult.SUBMIT)
override.hooks.press()
assert(customLow.content == "7000" and not customLow.enabled)
assert(not saved["554"].custom and saved["554"].low == 7000)
rules.styles.Magic.low = 6000
host.width = 401
refresh()
assert(customLow.content == "7000")
assert(require("warnings/settings").effective(rules, rules[4]).low == 6000)
override.hooks.press()
refresh()
assert(customLow.content == "7000")
assert(require("warnings/settings").effective(rules, rules[4]).low == 7000)
local activeColor = background.rgba
local before = changes
switch.value = false
switch.hooks.press()
assert(customLow.enabled and not customLow.clickthrough)
assert(not saved["554"].enabled and changes == before + 1 and background.rgba ~= activeColor)
assert(not switch.value)
assert(not require("warnings/settings").load()[4].enabled)
PersistentDB.SetStructuredData = function() return false end
switch.value = true
switch.hooks.press()
assert(not rules[4].enabled and background.rgba ~= activeColor and mode.content == "Failed")
assert(not switch.value and changes == before + 1)
PersistentDB.SetStructuredData = function(_, _, data) saved = data; return true end
switch.value = true
switch.hooks.press()
assert(saved["554"].enabled and customLow.enabled and background.rgba == activeColor)
assert(switch.value)
customCritical.content = "300"
customCritical.hooks.change(nil, ui.InputFieldActionResult.CONTENT_CHANGE)
customCritical.hooks.change(nil, ui.InputFieldActionResult.SUBMIT_ON_FOCUS_LOSS)
customLow.simulateProgrammaticChange, customCritical.simulateProgrammaticChange = true, true
override.hooks.press()
assert(not saved["554"].custom and customLow.content == "7000" and customCritical.content == "300")
assert(require("warnings/settings").effective(rules, rules[4]).low == 6000)
-- Client input events can arrive after the button changes modes.
customLow.hooks.change(customLow, ui.InputFieldActionResult.CONTENT_CHANGE)
customCritical.hooks.change(customCritical, ui.InputFieldActionResult.CONTENT_CHANGE)
customCritical.hooks.change(customCritical, ui.InputFieldActionResult.SUBMIT_ON_FOCUS_LOSS)
assert(mode.content ~= "Custom" and not saved["554"].custom)
assert(saved["554"].low == 7000 and saved["554"].critical == 300)
refresh()
override.hooks.press()
assert(saved["554"].custom and customLow.content == "7000" and customCritical.content == "300")
assert(saved["554"].low == 7000 and saved["554"].critical == 300)
local reloadedFire = require("warnings/settings").load()[4]
assert(reloadedFire.custom and reloadedFire.low == 7000 and reloadedFire.critical == 300)
customLow.simulateProgrammaticChange, customCritical.simulateProgrammaticChange = false, false
-- Collapsed sections release rows; scrolling virtualizes and restores drafts.
tabs.active = 4
for _, c in ipairs(controls) do
    for _, section in ipairs(ranged.sections) do
        assert(c.parent ~= section.content, "collapsed ranged sections must not allocate rows")
    end
end
ranged.sections[1]:SetExpanded(true)
refresh()
assert(find(ranged.content, "text", 10, 8).content == "Quivers unreadable; only loose supplies count.")
assert(find(ranged.sections[1].content, "sprite", 8, 3).itemId == 53055)
ranged.sections[2]:SetExpanded(true)
refresh()
assert(not ranged.sections[1].expanded, "only one ranged section stays open")
local arrow = ranged.sections[2].content
assert(find(arrow, "sprite", 8, 3).itemId == 52299)
assert(not find(arrow, "button", -251, 5).hidden)
ranged.sections[2]:SetExpanded(false)
for _, c in ipairs(controls) do
    if c.parent == arrow then assert(c.destroyed, "collapsed ranged rows must be released") end
end
ranged.sections[2]:SetExpanded(true)
refresh()
assert(find(arrow, "sprite", 8, 3).itemId == 52299)
local chinchompas = ranged.sections[4]
chinchompas:SetExpanded(true)
refresh()
assert(not ranged.sections[2].expanded)
assert(find(chinchompas.content, "sprite", 8, 3).itemId == 60791)
local large = ranged.sections[3] -- Enchanted Bakriminel Bolts
host.height = 300
large:SetExpanded(true)
ranged.scrollY = large.root.y + large.content.y
refresh()
local firstIcon = find(large.content, "sprite", 8, 3)
local firstSwitch = find(large.content, "check", -30, 7)
firstSwitch.hooks.press()
local firstId = firstIcon.itemId
assert(not saved[tostring(firstId)].enabled)
find(large.content, "button", -251, 5).hooks.press()
local draftLow = find(large.content, "input", -171, 5)
draftLow.content = "1234"
draftLow.hooks.change(draftLow, ui.InputFieldActionResult.CONTENT_CHANGE)
local function liveRows()
    local count = 0
    for _, c in ipairs(controls) do
        if c.parent == large.content and c.kind == "sprite" and not c.destroyed then count = count + 1 end
    end
    return count
end
assert(liveRows() <= math.ceil((host.height - 42) / 40) + 1)
ranged.scrollY = large.root.y + large.content.y + large.contentHeight - (host.height - 42)
refresh()
assert(firstIcon.destroyed, "offscreen rows must release their controls")
assert(find(large.content, "sprite", 8, large.contentHeight - 37))
assert(liveRows() <= math.ceil((host.height - 42) / 40) + 1)
ranged.scrollY = large.root.y + large.content.y
refresh()
assert(not find(large.content, "check", -30, 7).value, "recreated rows retain saved settings")
assert(find(large.content, "input", -171, 5).content == "1234", "scrolling retains an unsaved draft")
find(large.content, "check", -30, 7).hooks.press()
large:SetExpanded(false)
assert(liveRows() == 0)
host.height = 600
refresh()
-- Shared ammunition groups and the other combat-style tabs.
local rangedRows = find(ranged.content, "layer", 14, ranged.flowText.y)
assert(rangedRows.width == -28 and rangedRows.widthAnchor == 1)
local arrowSwitch = find(rangedRows, "check", -30, 47)
local boltSwitch = find(rangedRows, "check", -30, 87)
local collapsedY = rangedRows.y
host.height = 300
ranged.sections[1]:SetExpanded(true)
ranged.scrollY = 0
refresh()
assert(rangedRows.y == ranged.flowText.y and rangedRows.y > collapsedY)
assert(arrowSwitch.hidden, "rows below an expanded section are clipped outside the viewport")
ranged.scrollY = rangedRows.y
refresh()
assert(not arrowSwitch.hidden, "scrolling reaches the shared rows")
ranged.sections[1]:SetExpanded(false)
refresh()
assert(rangedRows.y == collapsedY and ranged.flowText.y == collapsedY)
host.height = 600
assert(find(rangedRows, "text", 48, 3).content == "Cannonballs")
assert(find(rangedRows, "text", 48, 43).content == "Arrows")
assert(find(rangedRows, "text", 48, 83).content == "Bolts")
assert(find(rangedRows, "text", 48, 123).content == "Gem Bolts")
assert(find(rangedRows, "text", 48, 163).content == "Bakriminel Bolts")
assert(find(rangedRows, "text", 48, 203).content == "Enchanted Gem Bolts")
assert(find(rangedRows, "sprite", 8, 3).itemId == 2)
find(rangedRows, "check", -30, 7).hooks.press()
assert(not saved["2"].enabled and not saved["59756"].enabled)
find(rangedRows, "button", -251, 5).hooks.press()
local cannonLow = find(rangedRows, "input", -171, 5)
cannonLow.content = "3000"
cannonLow.hooks.change(cannonLow, ui.InputFieldActionResult.SUBMIT)
assert(saved["2"].custom and saved["59756"].custom)
assert(saved["2"].low == 3000 and saved["59756"].low == 3000)
local cannonReload = require("warnings/settings").load()
for _, rule in ipairs(cannonReload) do
    if rule.itemId == 2 or rule.itemId == 59756 then
        assert(not rule.enabled and rule.custom and rule.low == 3000)
    end
end
arrowSwitch.hooks.press()
for _, itemId in ipairs({ 882, 31737, 19152, 19157, 19162, 58036, 34235 }) do
    assert(not saved[tostring(itemId)].enabled)
end
assert(saved["52299"].enabled and saved["53055"].enabled)
boltSwitch.hooks.press()
for _, itemId in ipairs({ 877, 28465, 35989, 58041, 60322 }) do
    assert(not saved[tostring(itemId)].enabled)
end
assert(saved["41633"].enabled and saved["9242"].enabled)
for _, group in ipairs({
    { y = 127, ids = { 879, 31868, 9342 }, other = 9236 },
    { y = 167, ids = { 24116, 41634, 41684 }, other = 41633 },
    { y = 207, ids = { 9236, 31881, 9245 }, other = 41633 },
}) do
    find(rangedRows, "check", -30, group.y).hooks.press()
    for _, itemId in ipairs(group.ids) do assert(not saved[tostring(itemId)].enabled) end
    assert(saved[tostring(group.other)].enabled)
end
find(rangedRows, "button", -251, 45).hooks.press()
local combinedLow = find(rangedRows, "input", -171, 45)
combinedLow.content = "2000"
combinedLow.hooks.change(combinedLow, ui.InputFieldActionResult.SUBMIT)
assert(saved["31737"].custom and saved["31737"].low == 2000 and saved["882"].low == 2000)
PersistentDB.SetStructuredData = function() return false end
arrowSwitch.hooks.press()
assert(not arrowSwitch.value)
assert(not saved["31737"].enabled and not saved["882"].enabled)
PersistentDB.SetStructuredData = function(_, _, data) saved = data; return true end
tabs.active = 5
refresh()
local meleeRows = find(melee.content, "layer", 14, melee.flowText.y)
assert(find(meleeRows, "sprite", 8, 3).itemId == 59925)
assert(find(meleeRows, "text", 48, 3).content == "Armour spikes")
tabs.active = 3
necro.sections[1]:SetExpanded(true)
refresh()
local necroRows = find(necro.content, "layer", 14, necro.flowText.y)
assert(find(necroRows, "text", 48, 3).content == "Ectoplasm")
assert(find(necroRows, "sprite", 8, 3).itemId == 55336)
local expandedNecroY = necroRows.y
necro.sections[1]:SetExpanded(false)
refresh()
assert(necroRows.y == necro.flowText.y and necroRows.y == expandedNecroY)
local ectoplasmSwitch = find(necroRows, "check", -30, 7)
ectoplasmSwitch.hooks.press()
assert(not saved["55336"].enabled)
ectoplasmSwitch.hooks.press()
tabs.active = 6
misc.sections[1]:SetExpanded(true)
refresh()
assert(find(misc.sections[1].content, "sprite", 8, 3).itemId == 48951)
assert(find(misc.sections[1].content, "sprite", 8, 43).itemId == 48954)
assert(find(misc.sections[1].content, "sprite", 8, 83).itemId == 48957)
assert(not find(misc.sections[1].content, "sprite", 8, 3).hidden)
misc.sections[2]:SetExpanded(true)
refresh()
assert(find(misc.sections[2].content, "sprite", 8, 3).itemId == 36389)
-- Reset is explicitly confirmed, scoped to one tab, persisted, and updates open rows.
local magicReset = find(magic.content, "button", -160, 5)
local magicCancel = find(magic.content, "button", -235, 5)
local magicResetLabel = find(magic.content, "text", -160, 5)
assert(magicReset.xAnchor == 1 and magicResetLabel.xAnchor == 1 and magicCancel.xAnchor == 1)
magicReset.hooks.press()
assert(magicResetLabel.content == "Confirm restore" and rules.styles.Magic.low == 6000)
magicCancel.hooks.press()
assert(magicResetLabel.content == "Restore to defaults" and rules[4].custom)
magicReset.hooks.press()
PersistentDB.SetStructuredData = function() return false end
magicReset.hooks.press()
assert(rules.styles.Magic.low == 6000 and rules[4].custom)
assert(magicResetLabel.content == "Save failed")
PersistentDB.SetStructuredData = function(_, _, data) saved = data; return true end
magicReset.hooks.press(); magicReset.hooks.press()
assert(rules.styles.Magic.low == 1000 and not rules[4].custom and rules[4].low == 1000)
assert(customLow.content == "1000" and not customLow.enabled and mode.content == "Defaults")
assert(saved.styles.Magic.low == 1000 and not saved["554"].custom)
assert(rules.checkOnPreset and rules.popupDuration == 15)
local generalReset = find(general.content, "button", -160, 5)
generalReset.hooks.press(); generalReset.hooks.press()
assert(rules.checkOnPreset and not rules.checkOnBankClose and rules.popupDuration == 4)
assert(preset.checkbox.items[1].selected and not bank.checkbox.items[1].selected)
assert(find(general.content, "input", 205, 150).content == "4")
local settings = require("warnings/settings")
for _, styleName in ipairs({ "Necromancy", "Ranged", "Melee", "Misc" }) do
    rules.styles[styleName].low = 2222
    for _, rule in ipairs(rules) do
        if settings.style(rule.itemId) == styleName then rule.enabled = false; break end
    end
end
rules.signOfLife = false
for i, page in ipairs({ necro, ranged, melee, misc }) do
    local styleName = ({ "Necromancy", "Ranged", "Melee", "Misc" })[i]
    local reset = find(page.content, "button", -160, 5)
    reset.hooks.press(); reset.hooks.press()
    assert(rules.styles[styleName].low == 1000 and saved.styles[styleName].low == 1000)
    for _, rule in ipairs(rules) do
        if settings.style(rule.itemId) == styleName then assert(rule.enabled) end
    end
end
assert(rules.signOfLife and sign.value and saved.signOfLife)
assert(saved["36389"].custom and saved["36389"].low == 50000)
destroy()
assert(tabs.destroyed)
-- Definitions, rather than renderer branches, control row/dropdown order and metadata.
local panels = require("warnings/settings-panels")
local miscDefinitions = panels[5].settings
miscDefinitions[1], miscDefinitions[9] = miscDefinitions[9], miscDefinitions[1]
local books = panels[5].dropdowns[3].settings
books[1], books[2] = books[2], books[1]
books[1].name, books[1].icon = "Custom book label", 123
controls = {}
host.height = 600
refresh, destroy = require("warnings/settings-view").build(host, rules, function() end, prettyui)
misc = tabs.pages[6]
miscRows = find(misc.content, "layer", 14, misc.flowText.y)
assert(find(miscRows, "text", 48, 3).content == "Blessed flask: warning unavailable")
assert(find(miscRows, "text", 48, 323).content == "Sign of life cooldown")
assert(find(misc.sections[3].content, "text", 48, 43).content == "Custom book label")
assert(find(misc.sections[3].content, "sprite", 8, 43).itemId == 123)
destroy()
miscDefinitions[1], miscDefinitions[9] = miscDefinitions[9], miscDefinitions[1]
books[1].name, books[1].icon = nil, nil
books[1], books[2] = books[2], books[1]
print("Warning settings view tests passed.")
