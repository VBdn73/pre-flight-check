local catalogue = require("supply-catalogue")
local settings = require("warnings/settings")
local view = {}

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

function view.build(host, rules, onChange, prettyui)
    assert(prettyui and prettyui.Tabs and prettyui.Tabs.new,
        "PrettyUI Tabs is required for warning settings")
    local tabs = prettyui.Tabs.new(host, {
        { text = "Magic" }, { text = "Necromancy" },
        { text = "Ranged" }, { text = "Melee" },
    }, { width = 0, height = 0, widthAnchor = 1, heightAnchor = 1 })
    local pages = { tabs:GetPage(1), tabs:GetPage(2) }
    local controls = { {}, {} }
    local pageIndex = 1
    local function track(control)
        local scroll = pages[pageIndex]
        local list = controls[pageIndex]
        list[#list + 1] = control
        control:Subscribe(ui.Hook.ONSCROLLWHEEL, "supplyCheck.scroll", function(_, delta)
            if not scroll.scrollbarVisible then return true end
            scroll:ScrollBy(delta * 32)
            return false
        end)
        return control
    end
    local originalText, originalButton, originalInput = text, button, input
    local function text(...) return track(originalText(...)) end
    local function button(...) return track(originalButton(...)) end
    local function input(...) return track(originalInput(...)) end
    local counts = { 0, 0 }
    text(pages[1].content, 10, 8, 400, "Rune counts include combat rune sources.")
    pageIndex = 2
    text(pages[2].content, 10, 8, 400, "Counts include loose supplies and the nexus.")
    for index, rule in ipairs(rules) do
        local item = catalogue[rule.itemId]
        pageIndex = item.category == "rune" and 1 or item.category == "necromancy" and 2 or nil
        if pageIndex then
        local parent = pages[pageIndex].content
        local y = 36 + counts[pageIndex] * 145
        counts[pageIndex] = counts[pageIndex] + 1
        text(parent, 10, y, 300, catalogue[rule.itemId].name)
        local enabled, zero = rule.enabled, rule.warnAtZero
        local enabledButton, zeroButton
        enabledButton = button(parent, 10, y + 23, 150, enabled and "Enabled" or "Disabled", function()
            enabled = not enabled
            enabledButton.label = enabled and "Enabled" or "Disabled"
        end)
        zeroButton = button(parent, 170, y + 23, 150, zero and "Warn at zero: on" or "Warn at zero: off", function()
            zero = not zero
            zeroButton.label = zero and "Warn at zero: on" or "Warn at zero: off"
        end)
        text(parent, 10, y + 53, 140, "Low / critical below")
        local low = input(parent, 10, y + 75, rule.low)
        local critical = input(parent, 80, y + 75, rule.critical)
        text(parent, 155, y + 53, 180, "Low / critical repeat (sec)")
        local lowCooldown = input(parent, 155, y + 75, rule.lowCooldown)
        local criticalCooldown = input(parent, 225, y + 75, rule.criticalCooldown)
        local status = text(parent, 110, y + 108, 330, "")
        button(parent, 10, y + 106, 90, "Save", function()
            local candidate = { itemId = rule.itemId, enabled = enabled, warnAtZero = zero,
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
    for i, page in ipairs(pages) do page:SetContentHeight(36 + counts[i] * 145) end
    local width, height, scrollPositions
    local function refresh()
        local w = math.max(1, host.width)
        local h = math.max(1, host.height - 42)
        if w ~= width or h ~= height then
            width, height, scrollPositions = w, h, {}
            for i = 1, 4 do tabs:GetPage(i)._scroll:Refresh() end
        end
        for i, page in ipairs(pages) do
            if page.scrollY ~= scrollPositions[i] then
                scrollPositions[i] = page.scrollY
                -- Input text and other native controls may draw outside the viewport.
                for _, control in ipairs(controls[i]) do
                    local top = control.y - page.scrollY
                    control.hidden = top < 0 or top + control.height > height
                end
            end
        end
    end
    refresh()
    return refresh, function() tabs:Destroy() end
end

return view
