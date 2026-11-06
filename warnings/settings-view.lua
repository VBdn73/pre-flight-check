local catalogue = require("supply-catalogue")
local settings = require("warnings/settings")
local spikes = require("armour-spikes")
local view = {}
local elemental = { [554] = true, [555] = true, [556] = true, [557] = true }
local combination = { [4694] = true, [4695] = true, [4696] = true,
    [4697] = true, [4698] = true, [4699] = true }
local rowHeight = 105

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
    local tabs = prettyui.Tabs.new(host, {
        { text = "Magic" }, { text = "Necromancy" },
        { text = "Ranged" }, { text = "Melee" },
    }, { width = 0, height = 0, widthAnchor = 1, heightAnchor = 1,
        contentLayout = { startY = 144 } })
    local pages = { tabs:GetPage(1), tabs:GetPage(2), tabs:GetPage(3), tabs:GetPage(4) }
    local styleNames = { "Magic", "Necromancy", "Ranged", "Melee" }
    local controls = { {}, {}, {}, {} }
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
    text(pages[1].content, 10, 8, 400, "Rune counts include combat rune sources.")
    local sections = { {}, {}, {}, {} }
    local function addSection(page, name)
        sections[page][name] = { count = 0, section = pages[page]:AddCollapseButton(name, {
            expanded = false, onToggle = function() layoutChanged = true end,
        }) }
    end
    for i, style in ipairs(styleNames) do
        pageIndex = i
        local parent = pages[i].content
        local rule = rules.styles[style]
        local zero = rule.warnAtZero
        local zeroButton
        text(parent, 10, 40, 200, style .. " defaults")
        zeroButton = button(parent, 227, 39, 80, zero and "Zero: on" or "Zero: off", function()
            zero = not zero
            zeroButton.label = zero and "Zero: on" or "Zero: off"
        end)
        text(parent, 10, 68, 140, "Low / critical below")
        local low = input(parent, 10, 87, rule.low)
        local critical = input(parent, 80, 87, rule.critical)
        text(parent, 155, 68, 180, "Low / critical repeat (sec)")
        local lowCooldown = input(parent, 155, 87, rule.lowCooldown)
        local criticalCooldown = input(parent, 225, 87, rule.criticalCooldown)
        local status = text(parent, 10, 115, 380, "")
        button(parent, 312, 39, 52, "Save", function()
            local candidate = { enabled = true, warnAtZero = zero, low = tonumber(low.content),
                critical = tonumber(critical.content), lowCooldown = tonumber(lowCooldown.content),
                criticalCooldown = tonumber(criticalCooldown.content) }
            if not settings.valid(candidate) then
                status.content = "Invalid: thresholds > 0, critical <= low; seconds 1-86400."
                return
            end
            local old = rules.styles[style]
            rules.styles[style] = candidate
            if not settings.save(rules) then
                rules.styles[style] = old
                status.content = "Could not save settings."
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
        icon(parent, 10, y, rule.itemId == spikes.ruleId and spikes.harnessId or rule.itemId)
        text(parent, 48, y + 5, 100, item.name)
        local enabled, zero, custom = rule.enabled, rule.warnAtZero, rule.custom
        local enabledButton, zeroButton
        enabledButton = button(parent, 150, y + 3, 72, enabled and "Enabled" or "Disabled", function()
            enabled = not enabled
            enabledButton.label = enabled and "Enabled" or "Disabled"
        end)
        local overrideButton
        overrideButton = button(parent, 227, y + 3, 80, custom and "Custom" or "Style", function()
            custom = not custom
            overrideButton.label = custom and "Custom" or "Style"
            layoutChanged = true
        end)
        local function customControl(control)
            controls[pageIndex][#controls[pageIndex]].visibleWhen = function() return custom end
            return control
        end
        zeroButton = customControl(button(parent, 310, y + 32, 80, zero and "Zero: on" or "Zero: off", function()
            zero = not zero
            zeroButton.label = zero and "Zero: on" or "Zero: off"
        end))
        customControl(text(parent, 10, y + 32, 140, "Low / critical below"))
        local low = customControl(input(parent, 10, y + 51, rule.low))
        local critical = customControl(input(parent, 80, y + 51, rule.critical))
        customControl(text(parent, 155, y + 32, 155, "Repeat (sec)"))
        local lowCooldown = customControl(input(parent, 155, y + 51, rule.lowCooldown))
        local criticalCooldown = customControl(input(parent, 225, y + 51, rule.criticalCooldown))
        local inherited = text(parent, 10, y + 43, 380, "Using style defaults")
        controls[pageIndex][#controls[pageIndex]].visibleWhen = function() return not custom end
        controls[pageIndex][#controls[pageIndex]].update = function()
            local shared = rules.styles[settings.style(rule.itemId)]
            inherited.content = string.format("Style: %d / %d; repeat %d / %ds; zero %s",
                shared.low, shared.critical, shared.lowCooldown, shared.criticalCooldown,
                shared.warnAtZero and "on" or "off")
        end
        local status = text(parent, 10, y + 79, 380, "")
        button(parent, 312, y + 3, 52, "Save", function()
            local candidate = { itemId = rule.itemId, enabled = enabled, custom = custom, warnAtZero = zero,
                low = tonumber(low.content), critical = tonumber(critical.content),
                lowCooldown = tonumber(lowCooldown.content), criticalCooldown = tonumber(criticalCooldown.content) }
            if not settings.valid(candidate) then
                status.content = "Invalid: thresholds > 0, critical <= low; seconds 1-86400."
                return
            end
            local old = rules[index]
            rules[index] = candidate
            if not settings.save(rules) then
                rules[index] = old
                status.content = "Could not save settings."
                return
            end
            onChange()
            status.content = "Saved."
        end)
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
        local active = tabs:GetActiveIndex()
        if active ~= activeIndex then activeIndex, layoutChanged = active, true end
        if w ~= width or h ~= height then
            width, height, scrollPositions = w, h, {}
            for i = 1, 4 do tabs:GetPage(i)._scroll:Refresh() end
        end
        for i, page in ipairs(pages) do
            if layoutChanged or page.scrollY ~= scrollPositions[i] then
                scrollPositions[i] = page.scrollY
                -- Input text and other native controls may draw outside the viewport.
                for _, entry in ipairs(controls[i]) do
                    local control, section = entry.control, entry.section
                    if entry.update then entry.update() end
                    local top = control.y - page.scrollY
                    if section then top = top + section.root.y + section.content.y end
                    control.hidden = active ~= i or (section and not section.expanded)
                        or (entry.visibleWhen and not entry.visibleWhen())
                        or top < 0 or top + control.height > height
                end
            end
        end
        layoutChanged = false
    end
    refresh()
    return refresh, function() tabs:Destroy() end
end

return view
