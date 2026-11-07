-- Short-lived, non-blocking warning overlay.
local popup = {}
local root, expires, scroll, hoverTargets
local rowHeight = 36

local function formatCount(count)
    local formatted = tostring(count)
    while true do
        local replacements
        formatted, replacements = formatted:gsub("^(%-?%d+)(%d%d%d)", "%1,%2")
        if replacements == 0 then return formatted end
    end
end

local function displayName(name, count)
    -- Some catalogue names are already plural, including enchanted bolts.
    local base, suffix = name:match("^(.-)( %(%a+%))$")
    base, suffix = base or name, suffix or ""
    if count == 1 then
        base = base:gsub(" arrows$", " arrow"):gsub(" bolts$", " bolt")
            :gsub(" spines$", " spine"):gsub(" spikes$", " spike")
    else
        base = base:gsub(" rune$", " runes"):gsub(" arrow$", " arrows")
            :gsub(" bolt(%s*%+%d*)$", " bolts%1"):gsub(" bolt$", " bolts")
            :gsub(" bomb$", " bombs"):gsub(" charge$", " charges")
            :gsub(" chinchompa$", " chinchompas"):gsub("^Chinchompa$", "Chinchompas")
            :gsub(" brutal$", " brutals"):gsub(" rack$", " racks")
            :gsub("^Dinarrow$", "Dinarrows")
    end
    return base .. suffix
end

function popup.formatAlert(alert)
    return alert.message or (displayName(alert.name, alert.count) .. ": " .. formatCount(alert.count))
end

function popup.colours(level)
    local critical = level == "critical"
    return critical and Vector4.new(0.34, 0.08, 0.08, 1) or Vector4.new(0.38, 0.20, 0.06, 1),
        critical and Vector4.new(0.95, 0.25, 0.20, 1) or Vector4.new(1, 0.58, 0.16, 1)
end

function popup.clear()
    local old = root
    local oldScroll = scroll
    root, expires, scroll, hoverTargets = nil, nil, nil, nil
    if oldScroll then pcall(function() oldScroll:Destroy() end) end
    if old then pcall(function() old:Destroy() end) end
end

function popup.show(alerts, now, duration, prettyui, maxRows)
    local parent = ui.Interfaces:GetComponent(id.Component.TOPLEVEL_V2__PLUGIN_BUILD_LAYER_TOP)
    if not parent then return false end
    popup.clear()
    local ok, err = pcall(function()
        root = ui.GroupBox.new(parent)
        root.stylesheetID = id.StyleSheet.DEFAULT
        root:SetHeaderLayout(0, 0, 0, 0, 0)
        root:SetPos(-170, 45, 0.5, 0)
        local listHeight = math.min(#alerts, maxRows or 8) * rowHeight
        if type(parent.height) == "number" and parent.height > 0 then
            listHeight = math.min(listHeight, math.max(1, parent.height - 45 - 42))
        end
        root:SetSize(340, 42 + listHeight)
        -- The root must receive mouse input for isMouseOver to detect hover.
        root.clickthrough = false
        local title = ui.Text.new(root)
        title:SetPos(10, 6); title:SetSize(320, 24)
        title.font = id.Font.MUSEO_SANS_15PT_REGULAR
        title.clickthrough = true
        title.content = "Supply Check"
        local listParent, rowWidth = root, 324
        if #alerts * rowHeight > listHeight then
            assert(prettyui and prettyui.SimpleView and prettyui.SimpleView.new, "PrettyUI SimpleView is required")
            scroll = prettyui.SimpleView.new(root, {
                x = 5, y = 32, width = 324, height = listHeight, scrollStep = rowHeight,
            })
            scroll:SetContentHeight(#alerts * rowHeight)
            listParent, rowWidth = scroll.content, scroll.contentWidth
            -- Interactive scroll children can receive hover instead of the popup root.
            hoverTargets = {}
            for _, key in ipairs({ "root", "viewport", "content", "upArrow", "downArrow",
                "track", "trackTop", "trackCentre", "trackBottom", "thumbDrag" }) do
                if scroll[key] then hoverTargets[#hoverTargets + 1] = scroll[key] end
            end
        end
        for i, alert in ipairs(alerts) do
            local critical = alert.level == "critical"
            local backgroundColour, accentColour = popup.colours(alert.level)
            local y = (scroll and 0 or 32) + (i - 1) * rowHeight
            local x = scroll and 0 or 5
            local box = ui.Rectangle.new(listParent)
            box:SetPos(x, y); box:SetSize(rowWidth, 32)
            box.fill = true
            box.colour = backgroundColour
            box.clickthrough = true
            local accent = ui.Rectangle.new(listParent)
            accent:SetPos(x, y); accent:SetSize(4, 32)
            accent.fill = true
            accent.colour = accentColour
            accent.clickthrough = true
            local label = ui.Text.new(listParent)
            label:SetPos(x + 12, y); label:SetSize(rowWidth - 104, 32)
            label.font = id.Font.MUSEO_SANS_15PT_REGULAR
            label.alignVertical = ui.AlignMode.CENTRE
            label.clickthrough = not scroll
            if scroll then
                hoverTargets[#hoverTargets + 1] = label
                label:Subscribe(ui.Hook.ONSCROLLWHEEL, "supplyCheck.popupScroll", function(_, delta)
                    if not scroll or not scroll.scrollbarVisible then return true end
                    scroll:ScrollBy(delta * rowHeight)
                    return false
                end)
            end
            label.content = popup.formatAlert(alert)
            local severity = ui.Text.new(listParent)
            severity:SetPos(x + rowWidth - 82, y); severity:SetSize(75, 32)
            severity.font = id.Font.MUSEO_SANS_11PT_REGULAR
            severity.alignHorizontal = ui.AlignMode.BOTTOMRIGHT
            severity.alignVertical = ui.AlignMode.CENTRE
            severity.clickthrough = true
            severity.content = alert.message and "" or (critical and "CRITICAL" or "LOW")
        end
        expires = now + (duration or 4)
    end)
    if not ok then
        popup.clear()
        print("[supply-check] Warning popup failed: " .. tostring(err))
        return false
    end
    return true
end

function popup.update(now)
    if not expires or now < expires then return end
    if root.isMouseOver or (scroll and scroll.dragStart) then return end
    if hoverTargets then
        for _, target in pairs(hoverTargets) do
            if target.isMouseOver then return end
        end
    end
    popup.clear()
end

return popup
