local catalogue = require("supply-catalogue")
local settings = require("warnings/settings")
local spikes = require("armour-spikes")
local view = {}
local elemental = { [554] = true, [555] = true, [556] = true, [557] = true }
local combination = { [4694] = true, [4695] = true, [4696] = true,
    [4697] = true, [4698] = true, [4699] = true }
local rowHeight = 40

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
    sprite:SetAssociatedObject(itemId)
    return sprite
end

function view.build(host, rules, onChange, prettyui)
    assert(prettyui and prettyui.Tabs and prettyui.Tabs.new,
        "PrettyUI Tabs is required for warning settings")
    assert(prettyui.CheckboxButton and prettyui.CheckboxButton.new,
        "PrettyUI CheckboxButton is required for warning settings")
    assert(prettyui.Tooltip and prettyui.Tooltip.attach,
        "PrettyUI Tooltip is required for warning settings")
    local tabs = prettyui.Tabs.new(host, {
        { text = "General" }, { text = "Magic" }, { text = "Necromancy" },
        { text = "Ranged" }, { text = "Melee" },
    }, { width = 0, height = 0, widthAnchor = 1, heightAnchor = 1,
        contentLayout = { startY = 120 } })
    local pages = { tabs:GetPage(2), tabs:GetPage(3), tabs:GetPage(4), tabs:GetPage(5), tabs:GetPage(1) }
    local styleNames = { "Magic", "Necromancy", "Ranged", "Melee" }
    local controls = { {}, {}, {}, {}, {} }
    local checkboxes, tooltips, tooltipTargets = {}, {}, {}
    local pageIndex, currentSection = 1, nil
    local layoutChanged = true
    local function track(control)
        local scroll = pages[pageIndex]
        local list = controls[pageIndex]
        list[#list + 1] = { control = control, section = currentSection }
        control:Subscribe(ui.Hook.ONSCROLLWHEEL, "supplyCheck.scroll", function(_, delta)
            if not scroll.scrollbarVisible then return true end
            scroll:ScrollBy(delta * 32)
            return false
        end)
        return control
    end
    local originalText, originalInput, originalIcon = text, input, icon
    local function text(...) return track(originalText(...)) end
    local function input(...) return track(originalInput(...)) end
    local function icon(...)
        local sprite = track(originalIcon(...))
        controls[pageIndex][#controls[pageIndex]].viewportClipped = true
        return sprite
    end
    local function tooltip(target, parent, value)
        local tip
        target:Subscribe(ui.Hook.ONMOUSEOVER, "supplyCheck.tooltipPosition", function()
            if tip then
                local x, y = target.x, target.y
                if tip.context and tip.context.active then x, y = tip.context.position(target) end
                tip.options.x = math.max(0, x + target.width - tip.width)
                tip.options.y = y - tip.height - 6
            end
            return true
        end)
        tip = prettyui.Tooltip.attach(target, parent, {
            text = value, placement = "above", constrainToParent = false,
        })
        tooltips[#tooltips + 1] = tip
        tooltipTargets[target] = tip
        return tip
    end
    local function onSubmit(field, callback, onEdit)
        field:Subscribe(ui.Hook.ONCONTENTCHANGED, function(_, reason)
            if onEdit and reason == ui.InputFieldActionResult.CONTENT_CHANGE then onEdit() end
            if reason == ui.InputFieldActionResult.SUBMIT
                or reason == ui.InputFieldActionResult.SUBMIT_ON_FOCUS_LOSS then callback() end
            return false
        end)
    end
    pageIndex = 5
    text(pages[5].content, 10, 8, 380, "Additional supply checks")
    local function triggerToggle(y, key, label)
        local checkbox
        checkbox = prettyui.CheckboxButton.new(pages[5].content, {
            { text = label, value = key, selected = rules[key] },
        }, { width = 300, onChange = function(_, _, _, selected)
            local old = rules[key]
            rules[key] = selected
            if not settings.save(rules) then
                rules[key] = old
                checkbox:SetSelected(key, old, false)
                print("[supply-check] Could not save check setting.")
            end
        end })
        checkbox.root:SetPos(10, y)
        checkbox.items[1].label.font = id.Font.MUSEO_SANS_11PT_REGULAR
        checkboxes[#checkboxes + 1] = checkbox
        track(checkbox.root)
    end
    triggerToggle(40, "checkOnPreset", "Check on preset load")
    triggerToggle(75, "checkOnBankClose", "Check on bank close")
    pageIndex = 1
    text(pages[1].content, 10, 8, 400, "Rune counts include combat rune sources.")
    local sections = { {}, {}, {}, {} }
    local function addSection(page, name)
        sections[page][name] = { count = 0, section = pages[page]:AddCollapseButton(name, {
            expanded = false, indent = 0, onToggle = function() layoutChanged = true end,
        }) }
    end
    for i, style in ipairs(styleNames) do
        pageIndex = i
        local parent = pages[i].content
        local rule = rules.styles[style]
        text(parent, 10, 40, 200, style .. " defaults")
        text(parent, 10, 68, 140, "Low / critical below")
        local low = input(parent, 10, 87, rule.low)
        local critical = input(parent, 80, 87, rule.critical)
        tooltip(low, parent, "Low warning quantity: warns below this value")
        tooltip(critical, parent, "Critical warning quantity: warns below this value")
        local status = text(parent, 160, 88, 100, "")
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
            status.content = "Saved."
        end
        onSubmit(low, saveDefaults)
        onSubmit(critical, saveDefaults)
    end
    currentSection = nil
    pageIndex = 1
    for _, name in ipairs({ "Elemental", "Catalytic", "Combination" }) do addSection(1, name) end
    pageIndex = 2
    text(pages[2].content, 10, 8, 400, "Counts include loose supplies and the nexus.")
    for _, name in ipairs({ "Necrotic Runes", "Ectoplasm" }) do addSection(2, name) end
    pageIndex = 3
    text(pages[3].content, 10, 8, 400, "Counts include loose ammunition.")
    addSection(3, "Ammunition")
    pageIndex = 4
    text(pages[4].content, 10, 8, 400, "Counts include loose spikes and one harness.")
    addSection(4, "Armour Spikes")
    for index, rule in ipairs(rules) do
        local item = rule.itemId == spikes.ruleId and spikes or catalogue[rule.itemId]
        pageIndex = rule.itemId == spikes.ruleId and 4
            or item.category == "rune" and 1 or item.category == "necromancy" and 2
            or item.category == "ammunition" and 3 or nil
        if pageIndex then
        local name
        if pageIndex == 1 then
            name = elemental[rule.itemId] and "Elemental"
                or combination[rule.itemId] and "Combination" or "Catalytic"
        elseif pageIndex == 2 then
            name = rule.itemId == 55336 and "Ectoplasm" or "Necrotic Runes"
        elseif pageIndex == 3 then
            name = "Ammunition"
        else
            name = "Armour Spikes"
        end
        local group = sections[pageIndex][name]
        currentSection = group.section
        local parent, y = currentSection.content, group.count * rowHeight
        group.count = group.count + 1
        -- PrettyUI's list uses a framed rectangle; use the same treatment for each row.
        local frame = track(ui.Rectangle.new(parent))
        local frameEntry = controls[pageIndex][#controls[pageIndex]]
        frame:SetPos(0, y); frame:SetSize(0, rowHeight - 4, 1, 0)
        frame.fill, frame.rgba, frame.clickthrough = true, 0x514D45C0, true
        controls[pageIndex][#controls[pageIndex]].background = { x = 0, y = y, width = 0, height = rowHeight - 4 }
        local background = track(ui.Rectangle.new(parent))
        background:SetPos(1, y + 1); background:SetSize(-2, rowHeight - 6, 1, 0)
        background.fill, background.clickthrough = true, true
        controls[pageIndex][#controls[pageIndex]].background = { x = 1, y = y + 1, width = -2, height = rowHeight - 6 }
        icon(parent, 8, y + 3, rule.itemId == spikes.ruleId and spikes.harnessId or rule.itemId).clickthrough = true
        local itemLabel = text(parent, 48, y + 8, 90, item.name)
        itemLabel:SetSize(-300, 22, 1, 0)
        itemLabel.clickthrough = true
        local enabled, custom = rule.enabled, rule.custom
        local draft = { tostring(rule.low), tostring(rule.critical) }
        local fields, mode, switch
        local settingFields = false
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
            if not settings.save(rules) then
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
        tooltip(switch, parent, "Enable or disable this warning")
        local modeButton = track(ui.Button.new(parent))
        modeButton:SetPos(-251, y + 5, 1, 0); modeButton:SetSize(75, 25)
        modeButton.stylesheetID = id.StyleSheet.BUTTON_DEFAULT
        modeButton:Subscribe(ui.Hook.ONBUTTONPRESSED, function()
            if custom then
                for i, field in ipairs(fields) do draft[i] = field.content end
            end
            local old = rules[index].custom
            rules[index].custom = not custom
            if not settings.save(rules) then
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
        tooltip(modeButton, parent, "Defaults: use style thresholds. Custom: use the item values shown. Click to switch.")
        mode = text(parent, -251, y + 5, 75, custom and "Custom" or "Defaults")
        mode:SetPos(-251, y + 5, 1, 0); mode:SetSize(75, 25)
        mode.alignHorizontal, mode.alignVertical = ui.AlignMode.CENTRE, ui.AlignMode.CENTRE
        mode.clickthrough = true
        local low = input(parent, -171, y + 5, rule.low)
        local critical = input(parent, -104, y + 5, rule.critical)
        low:SetPos(-171, y + 5, 1, 0)
        critical:SetPos(-104, y + 5, 1, 0)
        fields = { low, critical }
        for i, field in ipairs(fields) do
            local description = i == 1 and "Low warning quantity: warns below this value"
                or "Critical warning quantity: warns below this value"
            description = description .. ". Switch to Custom to set an item value."
            tooltip(field, parent, description)
        end
        local function editItem()
            if settingFields then return end
            if not custom then return end
            for i, field in ipairs(fields) do draft[i] = field.content end
        end
        local function saveItem()
            if settingFields then return end
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
            if not settings.save(rules) then
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
        updateRow()
        end
    end
    for _, pageSections in ipairs(sections) do
        for _, group in pairs(pageSections) do
            group.section:_SetContentHeight(group.count * rowHeight)
        end
    end
    local width, height, scrollPositions, activeIndex
    local function refresh()
        local w = math.max(1, host.width)
        local h = math.max(1, host.height - 42)
        local selected = tabs:GetActiveIndex()
        local active = selected == 1 and 5 or selected - 1
        if active ~= activeIndex then activeIndex, layoutChanged = active, true end
        if w ~= width or h ~= height then
            width, height, scrollPositions = w, h, {}
            for i = 1, 5 do tabs:GetPage(i)._scroll:Refresh() end
        end
        for i, page in ipairs(pages) do
            if layoutChanged or page.scrollY ~= scrollPositions[i] then
                scrollPositions[i] = page.scrollY
                -- Input text and other native controls may draw outside the viewport.
                for _, entry in ipairs(controls[i]) do
                    local control, section = entry.control, entry.section
                    if entry.update then entry.update() end
                    local box = entry.background
                    local top = (box and box.y or control.y) - page.scrollY
                    if section then top = top + section.root.y + section.content.y end
                    if box then
                        local inset = math.max(0, -top)
                        local clippedHeight = math.max(0, math.min(box.height - inset, height - math.max(0, top)))
                        control:SetPos(box.x, box.y + inset)
                        control:SetSize(box.width, clippedHeight, 1, 0)
                        control.hidden = active ~= i or (section and not section.expanded) or clippedHeight == 0
                    else
                    control.hidden = active ~= i or (section and not section.expanded)
                        or (entry.visibleWhen and not entry.visibleWhen())
                        or (entry.viewportClipped and (top >= height or top + control.height <= 0))
                        or (not entry.viewportClipped and (top < 0 or top + control.height > height))
                    end
                    if control.hidden and tooltipTargets[control] then tooltipTargets[control]:Hide() end
                end
            end
        end
        layoutChanged = false
    end
    refresh()
    return refresh, function()
        for _, tip in ipairs(tooltips) do tip:Destroy() end
        for _, checkbox in ipairs(checkboxes) do
            if checkbox.Destroy then checkbox:Destroy() end
        end
        tabs:Destroy()
    end
end

return view
