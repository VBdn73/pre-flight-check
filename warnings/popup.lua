-- Short-lived, non-blocking warning overlay.
local popup = {}
local root, expires, scroll, hoverTargets, drag, pinned, dragHandle
local rowHeight = 36
local positionKey = "supplyWarnings.popupPosition"
local iconView = require("warnings/popup-icons")
local tooltips = {}
local overlayPosition = require("warnings/overlay-position")

local validPosition = overlayPosition.valid

local function clampPosition(x, y, parent, height, width)
    return overlayPosition.clamp(x, y, parent, width or 340, height)
end

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
    if alert.status then return alert.name end
    return alert.message or (displayName(alert.name, alert.count) .. ": " .. formatCount(alert.count))
end

local function severityText(alert)
    return alert.status or (alert.message and "" or (alert.level == "critical" and "CRITICAL" or "LOW"))
end

function popup.wrapLabel(text, width, font)
    local function measure(value)
        if font then
            local ok, result = pcall(function() return font:GetStringWidth(value, true) end)
            if ok and type(result) == "number" then return result end
        end
        -- Conservative fallback if the client font metrics are unavailable.
        return #value * 15
    end
    local lines, line = {}, ""
    for character in text:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
        if character == "\n" then
            lines[#lines + 1], line = line, ""
        elseif line ~= "" and measure(line .. character) > width then
            local prefix, remainder = line:match("^(.*%s)(%S+)$")
            if prefix and measure(remainder .. character) <= width then
                lines[#lines + 1], line = prefix:gsub("%s+$", ""), remainder .. character
            else
                lines[#lines + 1], line = line:gsub("%s+$", ""), character
            end
        else
            line = line .. character
        end
    end
    lines[#lines + 1] = line
    return lines
end

function popup.colours(level, rules)
    local critical = level == "critical"
    local hex
    if rules then
        if critical then hex = rules.criticalColour else hex = rules.lowColour end
    end
    if hex then
        local rgb = require("warnings/colour").vector(hex)
        if rgb then
            return Vector4.new(rgb[1] * 0.36, rgb[2] * 0.36, rgb[3] * 0.36, 1),
                Vector4.new(rgb[1], rgb[2], rgb[3], 1)
        end
    end
    return critical and Vector4.new(0.34, 0.08, 0.08, 1) or Vector4.new(0.38, 0.20, 0.06, 1),
        critical and Vector4.new(0.95, 0.25, 0.20, 1) or Vector4.new(1, 0.58, 0.16, 1)
end

function popup.clear()
    for _, tip in ipairs(tooltips) do pcall(function() tip:Destroy() end) end
    tooltips = {}
    local old = root
    local oldScroll = scroll
    local oldHandle = dragHandle
    root, expires, scroll, hoverTargets, drag, pinned, dragHandle = nil, nil, nil, nil, nil, nil, nil
    if oldScroll then pcall(function() oldScroll:Destroy() end) end
    if oldHandle then pcall(function() oldHandle:Destroy() end) end
    if old then pcall(function() old:Destroy() end) end
end

function popup.show(alerts, now, duration, prettyui, maxRows, rules)
    local parent = ui.Interfaces:GetComponent(id.Component.TOPLEVEL_V2__PLUGIN_BUILD_LAYER_TOP)
    if not parent then return false end
    popup.clear()
    local ok, err = pcall(function()
        local iconMode = rules and rules.popupIconMode == true
        -- GroupBox adds a visible inset to its children; allow for that at the right edge too.
        local popupWidth = iconMode and 336 or 340
        local listWidth = iconMode and 318 or 324
        local headerWidth = iconMode and 213 or 225
        if iconMode then assert(prettyui and prettyui.Tooltip and prettyui.Tooltip.attach, "PrettyUI Tooltip is required") end
        local fontOK, labelFont = pcall(function() return config.Font.FromID(id.Font.MUSEO_SANS_15PT_REGULAR) end)
        if not fontOK then labelFont = nil end
        local function layout(width)
            if iconMode then
                local _, total, visible = iconView.layout(#alerts, width, maxRows)
                return {}, total, visible
            end
            local rows, total, visible = {}, 0, 0
            for i, alert in ipairs(alerts) do
                local labelWidth = width - (severityText(alert) ~= "" and 104 or 19)
                local lines = popup.wrapLabel(popup.formatAlert(alert), labelWidth, labelFont)
                local height = math.max(rowHeight, #lines * 24 + 8)
                rows[i] = { lines = lines, height = height, labelWidth = labelWidth }
                total = total + height
                if i <= (maxRows or 8) then visible = total end
            end
            return rows, total, visible
        end
        local rows, totalHeight, listHeight = layout(listWidth)
        local heightLimit = math.huge
        if type(parent.height) == "number" and parent.height > 0 then
            heightLimit = math.max(1, parent.height - 45 - 42)
        end
        listHeight = math.min(listHeight, heightLimit)
        local needsScroll = totalHeight > listHeight
        if needsScroll then
            -- SimpleView reserves space for its scrollbar; recalculate with its actual width below.
            rows, totalHeight, listHeight = layout(listWidth - 18)
            listHeight = math.min(listHeight, heightLimit)
        end
        root = ui.GroupBox.new(parent)
        root.stylesheetID = id.StyleSheet.DEFAULT
        root:SetHeaderLayout(0, 0, 0, 0, 0)
        root:SetSize(popupWidth, 42 + listHeight)
        local loaded, position = pcall(function() return PersistentDB:GetStructuredData(positionKey) end)
        if loaded and validPosition(position) then
            local x, y = clampPosition(position.x, position.y, parent, 42 + listHeight, popupWidth)
            root:SetPos(x, y)
        else
            root:SetPos(-popupWidth / 2, 45, 0.5, 0)
        end
        -- The root must receive mouse input for isMouseOver to detect hover.
        root.clickthrough = false
        local title = ui.Text.new(root)
        title:SetPos(10, 6); title:SetSize(headerWidth, 24)
        title.font = id.Font.MUSEO_SANS_15PT_REGULAR
        title.clickthrough = true
        title.content = "Pre flight check (" .. #alerts .. ")"
        dragHandle = ui.Layer.new(parent)
        dragHandle.clickthrough = false
        local function placeHandle()
            local origin, parentOrigin = root.xyGlobal, parent.xyGlobal
            if origin and parentOrigin then
                dragHandle:SetPos(origin.x - parentOrigin.x + 10, origin.y - parentOrigin.y + 6)
            end
            dragHandle:SetSize(headerWidth, 24)
            dragHandle:MoveToFront()
        end
        placeHandle()
        hoverTargets = { title, dragHandle }
        local function mousePosition()
            local ok, value = pcall(function() return Mouse.GetPosition() end)
            if ok and value and type(value.x) == "number" and type(value.y) == "number" then return value end
        end
        dragHandle:Subscribe(ui.Hook.ONCLICK, "supplyCheck.popupDragStart", function(_, x, y)
            if type(x) ~= "number" or type(y) ~= "number" then return false end
            local origin, parentOrigin = root.xyGlobal, parent.xyGlobal
            if not origin or not parentOrigin then return false end
            local raw = mousePosition()
            local expectedX, expectedY = origin.x + 10 + x, origin.y + 6 + y
            local sx = raw and math.abs(expectedX) >= 32 and raw.x / expectedX or nil
            local sy = raw and math.abs(expectedY) >= 32 and raw.y / expectedY or nil
            local scale
            if sx and sy and math.abs(sx - sy) <= (sx + sy) * 0.05 then
                scale = (sx + sy) / 2
            elseif sx and not sy and sx >= 0.5 and sx <= 4 then scale = sx
            elseif sy and not sx and sy >= 0.5 and sy <= 4 then scale = sy end
            if not scale or scale <= 0 then
                scale = (game and game.options and game.options.InterfaceScale
                    and tonumber(game.options.InterfaceScale.setting) or 100) / 100
                if scale <= 0 then scale = 1 end
            end
            drag = { x = x, y = y, rootX = origin.x - parentOrigin.x,
                rootY = origin.y - parentOrigin.y, raw = raw, scale = scale }
            dragHandle:SetPos(0, 0)
            dragHandle:SetSize(0, 0, 1, 1)
            dragHandle:MoveToFront()
            return false
        end)
        dragHandle:Subscribe(ui.Hook.ONHOLD, "supplyCheck.popupDragMove", function(_, x, y)
            if not drag or type(x) ~= "number" or type(y) ~= "number" then return false end
            local raw = mousePosition()
            local dx, dy = x - drag.x, y - drag.y
            if raw and drag.raw then
                dx, dy = (raw.x - drag.raw.x) / drag.scale, (raw.y - drag.raw.y) / drag.scale
            end
            local nextX = math.floor(drag.rootX + dx + 0.5)
            local nextY = math.floor(drag.rootY + dy + 0.5)
            nextX, nextY = clampPosition(nextX, nextY, parent, 42 + listHeight, popupWidth)
            root:SetPos(nextX, nextY)
            drag.moved = nextX ~= drag.rootX or nextY ~= drag.rootY
            drag.lastX, drag.lastY = nextX, nextY
            return false
        end)
        local function finishDrag()
            if drag and drag.moved then
                local position = { x = drag.lastX, y = drag.lastY }
                local ok, saved = pcall(function() return PersistentDB:SetStructuredData(positionKey, position) end)
                if not ok or saved ~= true then print("[pre-flight-check] Could not save popup position") end
            end
            drag = nil
            placeHandle()
            return false
        end
        dragHandle:Subscribe(ui.Hook.ONRELEASE, "supplyCheck.popupDragEnd", finishDrag)
        dragHandle:Subscribe(ui.Hook.ONDRAGCOMPLETE, "supplyCheck.popupDragComplete", finishDrag)
        local listParent, rowWidth = root, listWidth
        if needsScroll then
            assert(prettyui and prettyui.SimpleView and prettyui.SimpleView.new, "PrettyUI SimpleView is required")
            scroll = prettyui.SimpleView.new(root, {
                x = 5, y = 32, width = listWidth, height = listHeight, scrollStep = iconMode and 46 or rowHeight,
            })
            scroll:SetContentHeight(totalHeight)
            listParent, rowWidth = scroll.content, scroll.contentWidth
            if rowWidth ~= listWidth - 18 then
                rows, totalHeight = layout(rowWidth)
                scroll:SetContentHeight(totalHeight)
            end
            -- Interactive scroll children can receive hover instead of the popup root.
            for _, key in ipairs({ "root", "viewport", "content", "upArrow", "downArrow",
                "track", "trackTop", "trackCentre", "trackBottom", "thumbDrag" }) do
                if scroll[key] then hoverTargets[#hoverTargets + 1] = scroll[key] end
            end
        end
        local rowY = scroll and 0 or 32
        for i, alert in ipairs(alerts) do
            if iconMode then
                local background, accent = popup.colours(alert.level, rules)
                local columns = iconView.layout(#alerts, rowWidth, maxRows)
                iconView.draw({ parent = listParent, overlay = parent, x = scroll and 0 or 5, y = rowY,
                    background = background, accent = accent, prettyui = prettyui, tooltips = tooltips,
                    hoverTargets = hoverTargets, scroll = scroll, formatAlert = popup.formatAlert }, alert, i, columns)
            else
            local backgroundColour, accentColour = popup.colours(alert.level, rules)
            local y, height = rowY, rows[i].height
            rowY = rowY + height
            local x = scroll and 0 or 5
            local box = ui.Rectangle.new(listParent)
            box:SetPos(x, y); box:SetSize(rowWidth, height - 4)
            box.fill = true
            box.colour = backgroundColour
            box.clickthrough = true
            local accent = ui.Rectangle.new(listParent)
            accent:SetPos(x, y); accent:SetSize(4, height - 4)
            accent.fill = true
            accent.colour = accentColour
            accent.clickthrough = true
            for lineIndex, line in ipairs(rows[i].lines) do
                local label = ui.Text.new(listParent)
                label:SetPos(x + 12, y + (lineIndex - 1) * 24); label:SetSize(rows[i].labelWidth, #rows[i].lines == 1 and 32 or 24)
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
                label.content = line
            end
            local severity = ui.Text.new(listParent)
            severity:SetPos(x + rowWidth - 82, y); severity:SetSize(75, height - 4)
            severity.font = id.Font.MUSEO_SANS_11PT_REGULAR
            severity.alignHorizontal = ui.AlignMode.BOTTOMRIGHT
            severity.alignVertical = ui.AlignMode.CENTRE
            severity.clickthrough = true
            severity.content = severityText(alert)
            end
        end
        local pin = ui.Button.new(root)
        pin:SetPos(popupWidth - 100, 4); pin:SetSize(90, 25)
        pin.stylesheetID = id.StyleSheet.BUTTON_DEFAULT
        local pinLabel = ui.Text.new(root)
        pinLabel:SetPos(popupWidth - 100, 4); pinLabel:SetSize(90, 25)
        pinLabel.font = id.Font.MUSEO_SANS_11PT_REGULAR
        pinLabel.alignHorizontal = ui.AlignMode.CENTRE
        pinLabel.alignVertical = ui.AlignMode.CENTRE
        pinLabel.clickthrough = true
        pinLabel.content = "Keep open"
        hoverTargets[#hoverTargets + 1] = pin
        pin:Subscribe(ui.Hook.ONBUTTONPRESSED, function()
            if pinned then
                popup.clear()
            else
                pinned = true
                pinLabel.content = "Close"
            end
            return true
        end)
        expires = now + (duration or 4)
    end)
    if not ok then
        popup.clear()
        print("[pre-flight-check] Warning popup failed: " .. tostring(err))
        return false
    end
    return true
end

function popup.update(now)
    if not expires or pinned or now < expires then return end
    if drag or root.isMouseOver or (scroll and scroll.dragStart) then return end
    if hoverTargets then
        for _, target in pairs(hoverTargets) do
            if target.isMouseOver then return end
        end
    end
    popup.clear()
end

return popup
