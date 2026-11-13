local catalogue = require("supplies/catalogue")
local settings = require("warnings/settings")
local spikes = require("supplies/armour-spikes")
local colourValue = require("warnings/colour")
local components = require("warnings/settings-components")
local panels = require("warnings/settings-panels")
local settingsScroll = require("warnings/settings-scroll")
local view = {}
local elemental = { [554] = true, [555] = true, [556] = true, [557] = true }
local combination = { [4694] = true, [4695] = true, [4696] = true,
    [4697] = true, [4698] = true, [4699] = true }
local rowHeight = 40
local rangedCombinedNames, rangedCombinedIcons = {}, {}
for _, setting in ipairs(panels[3].settings) do
    rangedCombinedNames[#rangedCombinedNames + 1] = setting.name
    rangedCombinedIcons[setting.name] = setting.icon
end

local function text(parent, x, y, width, value)
    local label = ui.Text.new(parent)
    label:SetPos(x, y); label:SetSize(width, 22)
    label.font = id.Font.MUSEO_SANS_11PT_REGULAR
    label.content = value
    return label
end

local function input(parent, x, y, value)
    local field = ui.InputField.new(parent)
    field:SetPos(x, y); field:SetSize(64, 25)
    field.stylesheetID = id.StyleSheet.INPUT_DEFAULT
    field:Setup(ui.TextContentVisibilityMode.VISIBLE, ui.InputFieldFilterMode.NUMBERS_AS_TEXT, 10)
    field.content = tostring(value)
    return field
end

local function icon(parent, x, y, itemId)
    local sprite = ui.Sprite.new(parent)
    sprite:SetPos(x, y); sprite:SetSize(36, 32)
    if type(itemId) == "table" then
        sprite:SetPos(x + 2, y); sprite:SetSize(32, 32)
        sprite.sprite = itemId.sprite
    else
        sprite:SetAssociatedObject(itemId)
    end
    return sprite
end

function view.build(host, rules, onChange, prettyui)
    assert(prettyui and prettyui.Tabs and prettyui.Tabs.new,
        "PrettyUI Tabs is required for warning settings")
    assert(prettyui.CheckboxButton and prettyui.CheckboxButton.new,
        "PrettyUI CheckboxButton is required for warning settings")
    assert(prettyui.Tooltip and prettyui.Tooltip.attach,
        "PrettyUI Tooltip is required for warning settings")
    assert(prettyui.ColourPicker and prettyui.ColourPicker.new,
        "PrettyUI ColourPicker is required for warning settings")
    local tabs = prettyui.Tabs.new(host, {
        { text = "General" }, { text = "Magic" }, { text = "Necromancy" },
        { text = "Ranged" }, { text = "Melee" }, { text = "Misc" },
    }, { width = 0, height = 0, widthAnchor = 1, heightAnchor = 1,
        contentLayout = { startY = 80 } })
    local pages = { tabs:GetPage(2), tabs:GetPage(3), tabs:GetPage(4), tabs:GetPage(5), tabs:GetPage(6), tabs:GetPage(1) }
    local styleNames = {}
    for i, panel in ipairs(panels) do styleNames[i] = panel.name end
    local controls = { {}, {}, {}, {}, {}, {} }
    local checkboxes, tooltips, tooltipTargets = {}, {}, {}
    local createdControls, createdTooltips, createdRows = 0, 0, 0
    local pageIndex, currentSection, currentRow = 1, nil, nil
    local layoutChanged = true
    local resetControls = { {}, {}, {}, {}, {}, {} }
    local colourPickers = {}
    local inputClipTargets = {}
    local function dismissPicker()
        for _, picker in ipairs(colourPickers) do picker:Close() end
    end
    local function track(control)
        createdControls = createdControls + 1
        local scroll = pages[pageIndex]
        local list = controls[pageIndex]
        list[#list + 1] = { control = control, section = currentSection, row = currentRow }
        control:Subscribe(ui.Hook.ONSCROLLWHEEL, "supplyCheck.scroll", function(_, delta)
            if not scroll.scrollbarVisible then return true end
            scroll:ScrollBy(delta * 32)
            return false
        end)
        return control
    end
    local originalText, originalInput, originalIcon = text, input, icon
    local function text(...) return track(originalText(...)) end
    local function input(...)
        local field = track(originalInput(...))
        local controller = pages[pageIndex]._scroll
        inputClipTargets[#inputClipTargets + 1] = {
            controller = controller, target = settingsScroll.registerInput(controller, field),
        }
        return field
    end
    local function icon(...) return track(originalIcon(...)) end
    local function settingRow(parent, y, definition)
        return components.row({ track = track, entries = controls[pageIndex],
            text = text, icon = icon, rowHeight = rowHeight }, parent, y, definition)
    end
    local function tooltip(target, parent, value)
        -- PrettyUI tooltips own native controls too. Do not allocate a tooltip
        -- for every input/button in every hidden category during construction.
        local tip
        local options = { text = value, placement = "above", constrainToParent = false }
        local handle = {}
        function handle:Hide() if tip then tip:Hide() end end
        function handle:Destroy() if tip then tip:Destroy(); tip = nil end end
        target:Subscribe(ui.Hook.ONMOUSEOVER, "supplyCheck.tooltipPosition", function()
            if not tip then
                tip = prettyui.Tooltip.attach(target, parent, options)
                createdTooltips = createdTooltips + 1
                -- attach subscribes its own mouse hooks. The first mouse-over
                -- is already being dispatched, so show the new tip explicitly.
            end
            if tip then
                local x, y = target.x, target.y
                if tip.context and tip.context.active then x, y = tip.context.position(target) end
                tip.options.x = math.max(0, x + target.width - tip.width)
                tip.options.y = y - tip.height - 6
                if tip.Show then tip:Show() end
            end
            return true
        end)
        tooltips[#tooltips + 1] = handle
        tooltipTargets[target] = handle
        return handle
    end
    local function onSubmit(field, callback, onEdit)
        field:Subscribe(ui.Hook.ONCONTENTCHANGED, function(_, reason)
            if onEdit and reason == ui.InputFieldActionResult.CONTENT_CHANGE then onEdit() end
            if reason == ui.InputFieldActionResult.SUBMIT
                or reason == ui.InputFieldActionResult.SUBMIT_ON_FOCUS_LOSS then callback() end
            return false
        end)
    end
    pageIndex = 6
    text(pages[6].content, 10, 8, 380, "Additional supply checks")
    local chatCheckbox
    local function updateChatToggle()
        if not chatCheckbox then return end
        chatCheckbox:SetSelected("presetChatNotifications", rules.presetChatNotifications, false)
        chatCheckbox:SetDisabled(not rules.checkOnPreset)
    end
    local function triggerToggle(y, key, label)
        local checkbox
        checkbox = prettyui.CheckboxButton.new(pages[6].content, {
            { text = label, value = key, selected = rules[key] },
        }, { width = 300, onChange = function(_, _, _, selected)
            local old = rules[key]
            local oldChat = rules.presetChatNotifications
            if key == "presetChatNotifications" and not rules.checkOnPreset then
                checkbox:SetSelected(key, false, false)
                return
            end
            rules[key] = selected
            if key == "checkOnPreset" and not selected then rules.presetChatNotifications = false end
            if not settings.save(rules) then
                rules[key] = old
                rules.presetChatNotifications = oldChat
                checkbox:SetSelected(key, old, false)
                print("[pre-flight-check] Could not save check setting.")
            else
                onChange()
            end
            updateChatToggle()
        end })
        checkbox.root:SetPos(10, y)
        checkbox.items[1].label.font = id.Font.MUSEO_SANS_11PT_REGULAR
        checkboxes[#checkboxes + 1] = checkbox
        track(checkbox.root)
        resetControls[6][#resetControls[6] + 1] = function()
            checkbox:SetSelected(key, rules[key], false)
            updateChatToggle()
        end
        return checkbox
    end
    for i, definition in ipairs(panels.general.toggles) do
        local y = 40 + (i - 1) * 35
        local checkbox = triggerToggle(y, definition.key, definition.name)
        checkbox.root:SetPos(10 + (definition.indent or 0), y)
        if definition.usage then tooltip(checkbox.root, pages[6].content, definition.usage) end
        if definition.key == "presetChatNotifications" then chatCheckbox = checkbox end
    end
    updateChatToggle()
    local function numberControl(y, definition)
        local key = definition.key
        local label = text(pages[6].content, 10, y, 190, definition.name)
        label:SetSize(190, 25); label.alignVertical = ui.AlignMode.CENTRE
        local field = input(pages[6].content, 205, y, rules[key])
        local status = text(pages[6].content, 274, y, 110, "")
        status:SetSize(110, 25); status.alignVertical = ui.AlignMode.CENTRE
        tooltip(field, pages[6].content, definition.usage)
        onSubmit(field, function()
            local value = tonumber(field.content)
            if not definition.validate(value) then
                status.content = definition.invalid
                return
            end
            local old = rules[key]
            rules[key] = value
            if not settings.save(rules) then
                rules[key] = old
                status.content = "Save failed"
                return
            end
            status.content = ""
        end)
        resetControls[6][#resetControls[6] + 1] = function()
            field.content = tostring(rules[key])
            status.content = ""
        end
    end
    local generalNumbersY = 45 + #panels.general.toggles * 35
    for i, definition in ipairs(panels.general.numbers) do
        numberControl(generalNumbersY + (i - 1) * 35, definition)
    end
    local function colourControl(y, key, label, defaultHex)
        local title = text(pages[6].content, 10, y, 190, label)
        title:SetSize(190, 25); title.alignVertical = ui.AlignMode.CENTRE
        local status = text(pages[6].content, 274, y, 110, "")
        local picker
        picker = prettyui.ColourPicker.new(pages[6].content, {
            x = 205, y = y, width = 64, height = 25,
            windowParent = host, windowTitle = label,
            value = colourValue.rgba(rules[key] or defaultHex),
            onChange = function(_, value)
                local old = rules[key]
                rules[key] = string.format("#%06X", (value >> 8) & 0xFFFFFF)
                if not settings.save(rules) then
                    rules[key] = old
                    picker:SetValue(colourValue.rgba(old or defaultHex), false)
                    status.content = "Save failed"
                else
                    status.content = ""
                    onChange()
                end
            end,
        })
        picker.swatchFrame:SetPos(3, 3); picker.swatchFrame:SetSize(58, 19)
        picker.swatch:SetPos(4, 4); picker.swatch:SetSize(56, 17)
        -- PrettyUI's picker does not expose a draggable option, so adjust its
        -- window after opening while leaving the selector itself unchanged.
        local open = picker.Open
        function picker:Open()
            if not self.pickerWindow then
                local position, origin = self.root.xyGlobal, host.xyGlobal
                if position and origin then
                    local _, _, width, height = self:_PickerWindowBounds()
                    local x, y = position.x - origin.x, position.y - origin.y
                    local right = x + self.root.width + 8
                    if right + width > host.width then right = x - width - 8 end
                    self.options.windowX = math.max(0, math.min(right, host.width - width))
                    self.options.windowY = math.max(0, math.min(y, host.height - height))
                end
            end
            local result = open(self)
            if self.pickerWindow and self.pickerWindow.titleDrag then
                self.pickerWindow.titleDrag.hidden = true
            end
            return result
        end
        colourPickers[#colourPickers + 1] = picker
        track(picker.root)
        resetControls[6][#resetControls[6] + 1] = function()
            picker:SetValue(colourValue.rgba(rules[key] or defaultHex), false)
            status.content = ""
        end
    end
    local generalColoursY = generalNumbersY + #panels.general.numbers * 35
    for i, definition in ipairs(panels.general.colours) do
        colourControl(generalColoursY + (i - 1) * 35, definition.key, definition.name, definition.default)
    end
    pages[6]:SetContentHeight(generalColoursY + #panels.general.colours * 35)
    pageIndex = 1
    local sections = { {}, {}, {}, {}, {} }
    local toggleLazy
    local function addSection(page, definition)
        sections[page][definition.name] = components.dropdown(pages[page], definition,
            function(section, expanded)
                layoutChanged = true
                if expanded then
                    for _, group in pairs(sections[page]) do
                        if group.section ~= section and group.section.expanded then
                            group.section:SetExpanded(false)
                        end
                    end
                end
                if toggleLazy then toggleLazy(page, section, expanded) end
            end)
        sections[page][definition.name].definition = definition
    end
    for i, style in ipairs(styleNames) do
        pageIndex = i
        local parent = pages[i].content
        local rule = rules.styles[style]
        local label = text(parent, 10, 38, 150, style .. " defaults")
        label:SetSize(150, 25)
        label.alignVertical = ui.AlignMode.CENTRE
        local low = input(parent, 165, 38, rule.low)
        local critical = input(parent, 232, 38, rule.critical)
        tooltip(low, parent, "Low warning quantity: warns below this value")
        tooltip(critical, parent, "Critical warning quantity: warns below this value")
        local status = text(parent, 302, 38, 100, "")
        status:SetSize(100, 25)
        status.alignVertical = ui.AlignMode.CENTRE
        local function saveDefaults()
            local candidate = { enabled = true, low = tonumber(low.content),
                critical = tonumber(critical.content) }
            if not settings.valid(candidate) then
                status.content = "Invalid"
                return
            end
            local old = rules.styles[style]
            rules.styles[style] = candidate
            if not settings.save(rules) then
                rules.styles[style] = old
                status.content = "Save failed"
                return
            end
            onChange()
            layoutChanged = true
            status.content = ""
        end
        onSubmit(low, saveDefaults)
        onSubmit(critical, saveDefaults)
        resetControls[i][#resetControls[i] + 1] = function()
            low.content = tostring(rules.styles[style].low)
            critical.content = tostring(rules.styles[style].critical)
            status.content = ""
        end
    end
    currentSection = nil
    local spacers = {}
    for i, panel in ipairs(panels) do
        pageIndex = i
        text(pages[i].content, 10, 8, 400, panel.usage)
        local function reserveRows()
            if not panel.settings then return end
            spacers[i] = pages[i]:AddText({ text = "", height = #panel.settings * rowHeight })
            spacers[i].clickthrough = true
        end
        if panel.settingsFirst then reserveRows() end
        for _, definition in ipairs(panel.dropdowns) do
            addSection(i, definition)
            if definition.usage then
                local group = sections[i][definition.name]
                currentSection = group.section
                local note = text(group.section.content, 8, 8, 400, definition.usage)
                note:SetSize(-16, 25, 1, 0)
                note.clickthrough = true
                group.count = 1
                currentSection = nil
            end
        end
        if not panel.settingsFirst then reserveRows() end
    end
    local rangedSpacer, miscSpacer = spacers[3], spacers[5]
    pageIndex = 5
    local rowLayers = {}
    local function rowLayer(page, spacer, height)
        local layer = ui.Layer.new(pages[page].content)
        layer:SetPos(14, spacer.y); layer:SetSize(-28, height, 1, 0)
        layer.clickthrough = true
        -- Keep row tooltips in the page overlay, above sibling dropdown headers.
        local context = prettyui.Tooltip.getContext(pages[page].content)
        if context then
            prettyui.Tooltip.registerContext(layer, context.parent, function(target)
                local x, y = context.position(layer)
                return x + (target.x or 0), y + (target.y or 0)
            end, context)
        end
        rowLayers[#rowLayers + 1] = { layer = layer, spacer = spacer }
        return layer
    end
    local miscRows = rowLayer(5, miscSpacer, #panels[5].settings * rowHeight)
    local otherGroup = { count = 0 }
    local function addOtherSwitch(definition)
        local key, name = definition.key, definition.name
        local group = otherGroup
        local parent = miscRows
        local y = group.count * rowHeight
        local frameEntry, background = settingRow(parent, y, {
            name = name, icon = definition.icon, labelWidth = -85,
        })
        local switch = track(ui.Check.new(parent))
        switch:SetPos(-30, y + 7, 1, 0); switch:SetSize(22, 22)
        switch.stylesheetID = id.StyleSheet.CHECKBOX_DEFAULT
        switch.buttonSize = 22
        local function updateRow()
            background.rgba = rules[key] and 0x23412DE8 or 0x492626E8
            switch.value = rules[key]
        end
        switch:Subscribe(ui.Hook.ONBUTTONPRESSED, function()
            local old = rules[key]
            if (key == "itemDurability" or key == "beastOfBurden") and not old then
                local ok, permitted = pcall(function() return Plugin.HasPermission(PluginPermissions.chatAccess) end)
                if not rules.checkOnPreset or not rules.presetChatNotifications or not ok or not permitted then
                    return true
                end
            end
            rules[key] = not old
            if not settings.save(rules) then
                rules[key] = old
                updateRow()
                print("[pre-flight-check] Could not save " .. name .. " setting.")
                return true
            end
            updateRow()
            layoutChanged = true
            onChange()
            return true
        end)
        tooltip(switch, parent, definition.usage or "Enable or disable this warning")
        frameEntry.update = updateRow
        resetControls[5][#resetControls[5] + 1] = updateRow
        updateRow()
        group.count = group.count + 1
        currentSection = nil
    end
    local function addUnavailableRow(item)
        pageIndex = 5
        local group = otherGroup
        local parent = miscRows
            local y = group.count * rowHeight
            group.count = group.count + 1
            local _, background = settingRow(parent, y, {
                name = item.name .. ": warning unavailable", icon = item.icon, labelWidth = -55,
            })
            background.rgba = 0x343434E8
        currentSection = nil
    end
    local rowDrafts = {}
    local function buildRow(index, rule, item, group, rowPage, y, combined, rowParent)
        createdRows = createdRows + 1
        pageIndex = rowPage
        currentSection = group and group.section or nil
        local parent = currentSection and currentSection.content or rowParent or pages[rowPage].content
        local frameEntry, background = settingRow(parent, y, {
            name = item.name, icon = item.icon or (rule.itemId == spikes.ruleId and spikes.harnessId or rule.itemId),
        })
        local enabled, custom = rule.enabled, rule.custom
        local draft = rowDrafts[index] or { tostring(rule.low), tostring(rule.critical) }
        rowDrafts[index] = draft
        local fields, mode, switch
        local active = true
        frameEntry.deactivate = function() active = false end
        local settingFields = false
        local function saveCombined()
            if not combined then return settings.save(rules) end
            local old = {}
            for _, other in ipairs(combined) do
                if other ~= index then
                    old[other] = rules[other]
                    rules[other] = { itemId = rules[other].itemId, enabled = rules[index].enabled,
                        custom = rules[index].custom, low = rules[index].low, critical = rules[index].critical }
                end
            end
            if settings.save(rules) then return true end
            for other, value in pairs(old) do rules[other] = value end
            return false
        end
        local function setField(field, value)
            value = tostring(value)
            if field.content == value then return end
            settingFields = true
            field.content = value
            settingFields = false
        end
        local function updateRow()
            for _, field in ipairs(fields) do
                field.enabled = custom
                field.clickthrough = not custom
            end
            mode.content = custom and "Custom" or "Defaults"
            background.rgba = enabled and 0x23412DE8 or 0x492626E8
            switch.value = enabled
        end
        local function toggleEnabled()
            local old = rules[index].enabled
            rules[index].enabled = not old
            if not saveCombined() then
                rules[index].enabled = old
                switch.value = old
                mode.content = "Failed"
                return true
            end
            enabled = rules[index].enabled
            updateRow()
            layoutChanged = true
            onChange()
            return true
        end
        switch = track(ui.Check.new(parent))
        switch:SetPos(-30, y + 7, 1, 0); switch:SetSize(22, 22)
        switch.stylesheetID = id.StyleSheet.CHECKBOX_DEFAULT
        switch.buttonSize = 22
        switch:Subscribe(ui.Hook.ONBUTTONPRESSED, toggleEnabled)
        local variantName = catalogue[rule.itemId] and catalogue[rule.itemId].variantName
        tooltip(switch, parent, "Enable or disable this warning"
            .. (variantName and (". Also includes the non-illuminated " .. variantName .. ".") or ""))
        local modeButton = track(ui.Button.new(parent))
        modeButton:SetPos(-251, y + 5, 1, 0); modeButton:SetSize(75, 25)
        modeButton.stylesheetID = id.StyleSheet.BUTTON_DEFAULT
        modeButton:Subscribe(ui.Hook.ONBUTTONPRESSED, function()
            if item.godBook then return true end
            if custom then
                for i, field in ipairs(fields) do draft[i] = field.content end
            end
            local old = rules[index].custom
            rules[index].custom = not custom
            if not saveCombined() then
                rules[index].custom = old
                mode.content = "Failed"
                return true
            end
            custom = rules[index].custom
            if custom then for i, field in ipairs(fields) do setField(field, draft[i]) end end
            updateRow()
            layoutChanged = true
            onChange()
            return true
        end)
        tooltip(modeButton, parent, item.godBook and "Book thresholds are independent of Misc defaults."
            or "Defaults: use style thresholds. Custom: use the item values shown. Click to switch.")
        mode = text(parent, -251, y + 5, 75, custom and "Custom" or "Defaults")
        mode:SetPos(-251, y + 5, 1, 0); mode:SetSize(75, 25)
        mode.alignHorizontal, mode.alignVertical = ui.AlignMode.CENTRE, ui.AlignMode.CENTRE
        mode.clickthrough = true
        local low = input(parent, -171, y + 5, draft[1])
        local critical = input(parent, -104, y + 5, draft[2])
        low:SetPos(-171, y + 5, 1, 0)
        critical:SetPos(-104, y + 5, 1, 0)
        fields = { low, critical }
        for i, field in ipairs(fields) do
            local description = i == 1 and "Low warning quantity: warns below this value"
                or "Critical warning quantity: warns below this value"
            if item.godBook then
                description = (i == 1 and "Low" or "Critical")
                    .. " remaining time in minutes (0-1440); warns below this value."
            else
                description = description .. ". Switch to Custom to set an item value."
            end
            tooltip(field, parent, description)
        end
        local function editItem()
            if not active or settingFields then return end
            if not custom then return end
            for i, field in ipairs(fields) do draft[i] = field.content end
        end
        local function saveItem()
            if not active or settingFields then return end
            if not custom then return end
            if custom then for i, field in ipairs(fields) do draft[i] = field.content end end
            local candidate = { itemId = rule.itemId, enabled = enabled, custom = custom,
                low = tonumber(draft[1]), critical = tonumber(draft[2]) }
            if not settings.valid(candidate) then
                mode.content = "Invalid"
                return
            end
            local old = rules[index]
            rules[index] = candidate
            if not saveCombined() then
                rules[index] = old
                mode.content = "Failed"
                return
            end
            onChange()
            mode.content = custom and "Custom" or "Defaults"
        end
        onSubmit(low, saveItem, editItem)
        onSubmit(critical, saveItem, editItem)
        frameEntry.update = updateRow
        local function resetRow()
            local value = rules[index]
            enabled, custom = value.enabled, value.custom
            draft = { tostring(value.low), tostring(value.critical) }
            rowDrafts[index] = draft
            for i, field in ipairs(fields) do setField(field, draft[i]) end
            updateRow()
        end
        frameEntry.reset = resetRow
        if rowParent then resetControls[rowPage][#resetControls[rowPage] + 1] = resetRow end
        updateRow()
    end
    local combinedRows = {}
    for _, name in ipairs(rangedCombinedNames) do combinedRows[name] = {} end
    local function combinedName(itemId, item)
        if item.category ~= "ammunition" then return nil end
        if item.group == "Standard Arrows" or item.group == "Slayer and Other Arrows"
            or itemId == 31737 or itemId == 19152 or itemId == 19157 or itemId == 19162 then return "Arrows" end
        if item.group == "Special Bolts" or item.group == "Standard Bolts" then return "Bolts" end
        if combinedRows[item.group] then return item.group end
    end
    local orderedRules = {}
    local explicitOrder, itemDefinitions = {}, {}
    for _, panel in ipairs(panels) do
        for _, dropdown in ipairs(panel.dropdowns) do
            for position, definition in ipairs(dropdown.settings or {}) do
                explicitOrder[definition.itemId] = position
                itemDefinitions[definition.itemId] = definition
            end
        end
    end
    for index, rule in ipairs(rules) do orderedRules[#orderedRules + 1] = { index = index, rule = rule } end
    table.sort(orderedRules, function(a, b)
        local pa, pb = explicitOrder[a.rule.itemId] or math.huge, explicitOrder[b.rule.itemId] or math.huge
        if pa ~= pb then return pa < pb end
        return a.index < b.index
    end)
    local standalone = {}
    local miscRuleIndices = {}
    for _, entry in ipairs(orderedRules) do
        local index, rule = entry.index, entry.rule
        local item = rule.itemId == spikes.ruleId and spikes or catalogue[rule.itemId]
        local combined = combinedName(rule.itemId, item)
        if rule.itemId == 55336 or rule.itemId == spikes.ruleId then
            standalone[rule.itemId] = index
        elseif combined then
            combinedRows[combined][#combinedRows[combined] + 1] = index
        else
        pageIndex = rule.itemId == spikes.ruleId and 4
            or item.category == "rune" and 1 or item.category == "necromancy" and 2
            or item.category == "ammunition" and 3 or item.category == "misc" and 5 or nil
        if pageIndex then
        local name
        if pageIndex == 1 then
            name = elemental[rule.itemId] and "Elemental"
                or combination[rule.itemId] and "Combination" or "Catalytic"
        elseif pageIndex == 2 then
            name = "Necrotic Runes"
        elseif pageIndex == 3 or pageIndex == 5 then
            name = item.group
        end
        local group = pageIndex == 5 and name == "Other" and otherGroup or sections[pageIndex][name]
        local y = group.count * rowHeight
        if group == otherGroup then
            miscRuleIndices[rule.itemId] = index
        else
        group.count = group.count + 1
        if group.definition and group.definition.lazy then
            group.rows = group.rows or {}
            group.rows[#group.rows + 1] = { index = index, y = y }
        else
            local definition = itemDefinitions[rule.itemId] or {}
            buildRow(index, rule, { name = definition.name or item.name,
                icon = definition.icon, godBook = item.godBook }, group, pageIndex, y)
        end
        end
        end
        end
    end
    -- Match PrettyUI's flow padding and follow the managed spacer as sections reflow.
    local rangedRows = rowLayer(3, rangedSpacer, #rangedCombinedNames * rowHeight)
    for i, name in ipairs(rangedCombinedNames) do
        local indices = combinedRows[name]
        local representative = rangedCombinedIcons[name]
        local index
        for _, candidate in ipairs(indices) do
            if rules[candidate].itemId == representative then index = candidate; break end
        end
        buildRow(index, rules[index], { name = name, icon = representative }, nil, 3, (i - 1) * rowHeight, indices, rangedRows)
    end
    for _, page in ipairs({ 2, 4 }) do
        local definitions = panels[page].settings
        local layer = rowLayer(page, spacers[page], #definitions * rowHeight)
        for position, definition in ipairs(definitions) do
            local index = assert(standalone[definition.itemId], "Missing standalone setting rule")
            local item = definition.itemId == spikes.ruleId and spikes or catalogue[definition.itemId]
            buildRow(index, rules[index], { name = definition.name or item.name, icon = definition.icon },
                nil, page, (position - 1) * rowHeight, nil, layer)
        end
    end
    for _, definition in ipairs(panels[5].settings) do
        pageIndex = 5
        if definition.key then
            addOtherSwitch(definition)
        elseif definition.unavailable then
            addUnavailableRow(definition)
        else
            local index = assert(miscRuleIndices[definition.itemId], "Missing Misc setting rule")
            local item = catalogue[definition.itemId]
            buildRow(index, rules[index], { name = definition.name or item.name,
                icon = definition.icon, godBook = item.godBook }, otherGroup, 5,
                otherGroup.count * rowHeight, nil, miscRows)
            otherGroup.count = otherGroup.count + 1
        end
    end
    -- Build a lazy section once on opening, not as individual rows enter the
    -- viewport. Keep their native controls and input identity while scrolling.
    toggleLazy = function(page, section, expanded)
        local selected
        for _, group in pairs(sections[page]) do
            if group.section == section then selected = group; break end
        end
        if not selected or not selected.rows then return end
        if not expanded then
            for _, entry in ipairs(controls[page]) do
                if entry.section == section and entry.row then
                    entry.control.hidden = true
                    local tip = tooltipTargets[entry.control]
                    if tip then tip:Hide() end
                end
            end
        end
        currentSection = nil
    end
    for _, pageSections in ipairs(sections) do
        for _, group in pairs(pageSections) do
            group.section:_SetContentHeight(group.count * rowHeight)
        end
    end
    currentSection = nil
    for i, page in ipairs(pages) do
        pageIndex = i
        local button = track(ui.Button.new(page.content))
        button:SetPos(-160, 5, 1, 0); button:SetSize(150, 25)
        button.stylesheetID = id.StyleSheet.BUTTON_DEFAULT
        local label = text(page.content, -160, 5, 150, "Restore to defaults")
        label:SetPos(-160, 5, 1, 0)
        label:SetSize(150, 25)
        label.alignHorizontal, label.alignVertical = ui.AlignMode.CENTRE, ui.AlignMode.CENTRE
        label.clickthrough = true
        local confirming = false
        local cancel = track(ui.Button.new(page.content))
        cancel:SetPos(-235, 5, 1, 0); cancel:SetSize(70, 25)
        cancel.stylesheetID = id.StyleSheet.BUTTON_DEFAULT
        controls[i][#controls[i]].visibleWhen = function() return confirming end
        local cancelLabel = text(page.content, -235, 5, 70, "Cancel")
        cancelLabel:SetPos(-235, 5, 1, 0)
        cancelLabel:SetSize(70, 25)
        cancelLabel.alignHorizontal, cancelLabel.alignVertical = ui.AlignMode.CENTRE, ui.AlignMode.CENTRE
        cancelLabel.clickthrough = true
        controls[i][#controls[i]].visibleWhen = function() return confirming end
        cancel:Subscribe(ui.Hook.ONBUTTONPRESSED, function()
            confirming = false
            label.content = "Restore to defaults"
            layoutChanged = true
            return true
        end)
        button:Subscribe(ui.Hook.ONBUTTONPRESSED, function()
            if not confirming then
                confirming = true
                label.content = "Confirm restore"
                layoutChanged = true
                return true
            end
            confirming = false
            label.content = "Restore to defaults"
            layoutChanged = true
            local defaults = settings.defaults()
            local old = {}
            if i == 6 then
                dismissPicker()
                for _, key in ipairs({ "checkOnPreset", "presetChatNotifications", "checkOnBankClose", "checkOnPortalEntry", "showCheckButton", "popupIconMode", "popupDuration", "popupRows", "lowColour", "criticalColour" }) do
                    old[key], rules[key] = rules[key], defaults[key]
                end
            else
                local style = styleNames[i]
                old.style, rules.styles[style] = rules.styles[style], defaults.styles[style]
                if style == "Misc" then
                    old.signOfLife, rules.signOfLife = rules.signOfLife, defaults.signOfLife
                    old.excalibur, rules.excalibur = rules.excalibur, defaults.excalibur
                    old.powerburst, rules.powerburst = rules.powerburst, defaults.powerburst
                    old.deathReclaim, rules.deathReclaim = rules.deathReclaim, defaults.deathReclaim
                    old.itemDurability, rules.itemDurability = rules.itemDurability, defaults.itemDurability
                    old.beastOfBurden, rules.beastOfBurden = rules.beastOfBurden, defaults.beastOfBurden
                end
                for index, rule in ipairs(rules) do
                    if settings.style(rule.itemId) == style then
                        old[index], rules[index] = rule, defaults[index]
                    end
                end
            end
            if not settings.save(rules) then
                if i == 6 then
                    for _, key in ipairs({ "checkOnPreset", "presetChatNotifications", "checkOnBankClose", "checkOnPortalEntry", "showCheckButton", "popupIconMode", "popupDuration", "popupRows", "lowColour", "criticalColour" }) do rules[key] = old[key] end
                else
                    rules.styles[styleNames[i]] = old.style
                    if i == 5 then
                        rules.signOfLife, rules.deathReclaim, rules.itemDurability = old.signOfLife, old.deathReclaim, old.itemDurability
                        rules.beastOfBurden = old.beastOfBurden
                        rules.excalibur = old.excalibur
                        rules.powerburst = old.powerburst
                    end
                    for index, rule in pairs(old) do if type(index) == "number" then rules[index] = rule end end
                end
                label.content = "Save failed"
                return true
            end
            if i ~= 6 then
                for index in pairs(old) do if type(index) == "number" then rowDrafts[index] = nil end end
            end
            for _, update in ipairs(resetControls[i]) do update() end
            for _, entry in ipairs(controls[i]) do if entry.reset then entry.reset() end end
            layoutChanged = true
            onChange()
            return true
        end)
    end
    local width, height, scrollPositions, activeIndex
    local function refresh()
        for _, entry in ipairs(rowLayers) do
            if entry.layer.y ~= entry.spacer.y then
                entry.layer:SetPos(14, entry.spacer.y)
                layoutChanged = true
            end
        end
        local w = math.max(1, host.width)
        local h = math.max(1, host.height - 42)
        local selected = tabs:GetActiveIndex()
        local active = selected == 1 and 6 or selected - 1
        if active ~= 6 then dismissPicker() end
        if active ~= activeIndex then activeIndex, layoutChanged = active, true end
        if w ~= width or h ~= height then
            width, height, scrollPositions = w, h, {}
            for i = 1, 6 do tabs:GetPage(i)._scroll:Refresh() end
        end
        if active == 3 then
            for _, group in pairs(sections[3]) do
                if group.rows and group.section.expanded then
                    if not group.built then
                        for _, row in ipairs(group.rows) do
                            currentRow = row.index
                            local rule = rules[row.index]
                            buildRow(row.index, rule, catalogue[rule.itemId], group, 3, row.y)
                        end
                        group.built = true
                        layoutChanged = true
                    end
                    currentRow, currentSection = nil, nil
                end
            end
        end
        for i, page in ipairs(pages) do
            if page.scrollY ~= scrollPositions[i] then
                scrollPositions[i] = page.scrollY
                for _, entry in ipairs(controls[i]) do
                    local tip = tooltipTargets[entry.control]
                    if tip then tip:Hide() end
                end
            end
            if layoutChanged then
                -- Tabs and collapsed sections own visibility. Viewport clipping
                -- belongs exclusively to PrettyUI's native scroll container.
                for _, entry in ipairs(controls[i]) do
                    local control, section = entry.control, entry.section
                    if entry.update then entry.update() end
                    local hidden = active ~= i or (section and not section.expanded)
                        or (entry.visibleWhen and not entry.visibleWhen())
                    hidden = not not hidden
                    if control.hidden ~= hidden then control.hidden = hidden end
                    if control.hidden and tooltipTargets[control] then tooltipTargets[control]:Hide() end
                end
            end
        end
        layoutChanged = false
    end
    local function checkedRefresh()
        local ok, err = pcall(refresh)
        if not ok then
            error(tostring(err) .. string.format(" [settings allocations: controls=%d, rows=%d, tooltips=%d]",
                createdControls, createdRows, createdTooltips), 0)
        end
    end
    checkedRefresh()
    return checkedRefresh, function()
        for _, entries in ipairs(controls) do
            for _, entry in ipairs(entries) do
                if entry.deactivate then entry.deactivate() end
            end
        end
        dismissPicker()
        for _, entry in ipairs(inputClipTargets) do
            entry.controller:UnregisterClipTarget(entry.target)
        end
        for _, picker in ipairs(colourPickers) do picker:Destroy() end
        for _, tip in ipairs(tooltips) do tip:Destroy() end
        for _, checkbox in ipairs(checkboxes) do
            if checkbox.Destroy then checkbox:Destroy() end
        end
        tabs:Destroy()
    end
end

return view
