local catalogue = require("supply-catalogue")
local settings = require("warnings/settings")
local spikes = require("armour-spikes")
local view = {}
local elemental = { [554] = true, [555] = true, [556] = true, [557] = true }
local combination = { [4694] = true, [4695] = true, [4696] = true,
    [4697] = true, [4698] = true, [4699] = true }
local rowHeight = 90

local function text(parent, x, y, width, value)
    local label = ui.Text.new(parent)
    label:SetPos(x, y); label:SetSize(width, 22)
    label.font = id.Font.MUSEO_SANS_11PT_REGULAR
    label.content = value
    return label
end

local function button(parent, x, y, width, label, callback)
    local b = ui.Button.new(parent)
    b:SetPos(x, y); b:SetSize(width, 25)
    b.stylesheetID = id.StyleSheet.BUTTON_DEFAULT
    b.label = label
    b:Subscribe(ui.Hook.ONBUTTONPRESSED, callback)
    return b
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
    assert(prettyui.SpriteButton and prettyui.SpriteButton.new,
        "PrettyUI SpriteButton is required for warning settings")
    assert(prettyui.CheckboxButton and prettyui.CheckboxButton.new,
        "PrettyUI CheckboxButton is required for warning settings")
    local tabs = prettyui.Tabs.new(host, {
        { text = "General" }, { text = "Magic" }, { text = "Necromancy" },
        { text = "Ranged" }, { text = "Melee" },
    }, { width = 0, height = 0, widthAnchor = 1, heightAnchor = 1,
        contentLayout = { startY = 120 } })
    local pages = { tabs:GetPage(2), tabs:GetPage(3), tabs:GetPage(4), tabs:GetPage(5), tabs:GetPage(1) }
    local styleNames = { "Magic", "Necromancy", "Ranged", "Melee" }
    local controls = { {}, {}, {}, {}, {} }
    local spriteButtons, checkboxes = {}, {}
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
    local originalText, originalButton, originalInput, originalIcon = text, button, input, icon
    local function text(...) return track(originalText(...)) end
    local function button(...) return track(originalButton(...)) end
    local function input(...) return track(originalInput(...)) end
    local function icon(...) return track(originalIcon(...)) end
    local function iconButton(parent, x, y, sprite, tooltip, action, toggleable, disabled)
        local b = prettyui.SpriteButton.new(parent, sprite, action, {
            x = x, y = y, size = 25, tooltip = tooltip,
            toggleable = toggleable, disabled = disabled,
        })
        spriteButtons[#spriteButtons + 1] = b
        track(b.root)
        return b
    end
    local function saveButton(parent, x, y, action)
        return button(parent, x, y, 48, "Save", action)
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
        local status = text(parent, 300, 88, 85, "")
        saveButton(parent, 227, 39, function()
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
        end)
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
        frame:SetPos(0, y); frame:SetSize(0, rowHeight - 4, 1, 0)
        frame.fill, frame.rgba, frame.clickthrough = true, 0x514D45C0, true
        controls[pageIndex][#controls[pageIndex]].background = { x = 0, y = y, width = 0, height = rowHeight - 4 }
        local background = track(ui.Rectangle.new(parent))
        background:SetPos(1, y + 1); background:SetSize(-2, rowHeight - 6, 1, 0)
        background.fill, background.clickthrough = true, true
        controls[pageIndex][#controls[pageIndex]].background = { x = 1, y = y + 1, width = -2, height = rowHeight - 6 }
        icon(parent, 8, y + 3, rule.itemId == spikes.ruleId and spikes.harnessId or rule.itemId)
        text(parent, 48, y + 8, 100, item.name)
        local enabled, custom = rule.enabled, rule.custom
        local draft = { tostring(rule.low), tostring(rule.critical) }
        local fields, mode
        local function updateRow()
            local shared = rules.styles[settings.style(rule.itemId)]
            local values = custom and draft or { shared.low, shared.critical }
            for i, field in ipairs(fields) do
                if not custom then field.content = tostring(values[i]) end
                field.enabled = custom and enabled
                field.clickthrough = not field.enabled
            end
            mode.content = custom and "Custom" or "Style"
            background.rgba = enabled and (custom and 0x211F1BE8 or 0x171512D8) or 0x252525B0
        end
        iconButton(parent, 150, y + 5, "EYE", "Enable or disable this warning", function(_, active)
            enabled = active
            updateRow()
        end, true, not enabled)
        iconButton(parent, 180, y + 5, "PENCIL", "Switch between style defaults and custom settings", function(_, active)
            if custom then
                for i, field in ipairs(fields) do draft[i] = field.content end
            end
            custom = active
            if custom then for i, field in ipairs(fields) do field.content = draft[i] end end
            updateRow()
        end, true, not custom)
        mode = text(parent, 210, y + 8, 55, custom and "Custom" or "Style")
        text(parent, 10, y + 35, 140, "Low / critical below")
        local low = input(parent, 10, y + 54, rule.low)
        local critical = input(parent, 80, y + 54, rule.critical)
        fields = { low, critical }
        local status = text(parent, 300, y + 55, 85, "")
        saveButton(parent, 265, y + 5, function()
            if custom then for i, field in ipairs(fields) do draft[i] = field.content end end
            local candidate = { itemId = rule.itemId, enabled = enabled, custom = custom,
                low = tonumber(draft[1]), critical = tonumber(draft[2]) }
            if not settings.valid(candidate) then
                status.content = "Invalid"
                return
            end
            local old = rules[index]
            rules[index] = candidate
            if not settings.save(rules) then
                rules[index] = old
                status.content = "Save failed"
                return
            end
            onChange()
            status.content = "Saved."
        end)
        controls[pageIndex][#controls[pageIndex]].update = updateRow
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
                        or top < 0 or top + control.height > height
                    end
                end
            end
        end
        layoutChanged = false
    end
    refresh()
    return refresh, function()
        for _, b in ipairs(spriteButtons) do b:Destroy() end
        for _, checkbox in ipairs(checkboxes) do
            if checkbox.Destroy then checkbox:Destroy() end
        end
        tabs:Destroy()
    end
end

return view
