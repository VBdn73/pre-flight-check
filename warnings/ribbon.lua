-- The client owns the content layer; retain only the last notification batch.
local popup = require("warnings/popup")
local ribbon = {}
local latest, timestamp, refresh, destroy = {}, nil, nil, nil
local rowHeight, listTop = 36, 36

local function clock()
    -- This is the clock shown by the client, which can be set to server or local time.
    local ok, value = pcall(function()
        local component = ui.Interfaces:GetComponent(id.Component.TOPLEVEL_V2_MINIMAP__CLOCK_TEXT)
        return component and component.content
    end)
    if ok and type(value) == "string" then
        local hour, minute = value:match("(%d%d?):(%d%d)")
        if hour and tonumber(hour) < 24 and tonumber(minute) < 60 then
            return string.format("%02d:%s", tonumber(hour), minute)
        end
    end
    return "unavailable"
end

function ribbon.record(alerts)
    latest = {}
    for i, alert in ipairs(alerts) do
        latest[i] = { name = alert.name, count = alert.count, message = alert.message, level = alert.level, status = alert.status }
    end
    timestamp = clock()
    if refresh and not pcall(refresh, true) then ribbon.close() end
end

function ribbon.open(parent, prettyui, rules)
    ribbon.close()
    assert(prettyui and prettyui.SimpleView and prettyui.SimpleView.new, "PrettyUI SimpleView is required")
    local function text(y, height)
        local label = ui.Text.new(parent)
        label:SetPos(10, y); label:SetSize(-20, height, 1, 0)
        label.font = id.Font.MUSEO_SANS_11PT_REGULAR
        return label
    end
    local title = text(10, 24)
    local scroll = prettyui.SimpleView.new(parent, {
        x = 0, y = listTop, width = math.max(1, parent.width),
        height = math.max(1, parent.height - listTop), scrollStep = rowHeight,
    })
    destroy = function()
        pcall(function() scroll:Destroy() end)
        pcall(function() title:Destroy() end)
    end
    local rows = {}
    local function addLabel(row)
        local label = ui.Text.new(scroll.content)
        label.font = id.Font.MUSEO_SANS_11PT_REGULAR
        label.alignVertical = ui.AlignMode.CENTRE
        label:Subscribe(ui.Hook.ONSCROLLWHEEL, "supplyCheck.ribbonScroll", function(_, delta)
            if not scroll.scrollbarVisible then return true end
            scroll:ScrollBy(delta * rowHeight)
            return false
        end)
        row.labels[#row.labels + 1] = label
    end
    local function addRow()
        local background = ui.Rectangle.new(scroll.content)
        background.fill = true; background.clickthrough = true
        local accent = ui.Rectangle.new(scroll.content)
        accent.fill = true; accent.clickthrough = true
        local row = { background = background, accent = accent, labels = {} }
        addLabel(row)
        rows[#rows + 1] = row
    end
    local fontOK, font = pcall(function() return config.Font.FromID(id.Font.MUSEO_SANS_11PT_REGULAR) end)
    if not fontOK then font = nil end
    local width, height, count, layout
    local function render(reset)
        local w, h = math.max(1, parent.width), math.max(1, parent.height - listTop)
        local resized = w ~= width or h ~= height
        if resized then
            width, height = w, h
            scroll:SetSize(w, h)
        end
        if reset or resized or count ~= #latest then
            count = #latest
            local function buildLayout(contentWidth)
                local entries, total = {}, 0
                for i, alert in ipairs(latest) do
                    local text = popup.formatAlert(alert) .. (alert.status and " - " .. alert.status or "")
                    local lines = popup.wrapLabel(text, math.max(1, contentWidth - 27), font)
                    local rowSize = math.max(rowHeight, #lines * 18 + 8)
                    entries[i] = { y = total, height = rowSize, lines = lines }
                    total = total + rowSize
                end
                return entries, total
            end
            -- First lay out without a scrollbar, then reflow if one is needed.
            local total
            layout, total = buildLayout(w)
            scroll:SetContentHeight(total)
            if scroll.contentWidth ~= w then
                layout, total = buildLayout(scroll.contentWidth)
                scroll:SetContentHeight(total)
            end
            if reset then scroll:SetScrollPosition(0) end
        end
        title.content = "Last notifications (" .. count .. ")" .. (timestamp and ": " .. timestamp or "")
        -- Reuse only enough native controls for the viewport, even for large batches.
        local needed = math.min(count, math.ceil(height / rowHeight) + 1)
        while #rows < needed do addRow() end
        local first = 1
        while first <= count and layout[first].y + layout[first].height <= scroll.scrollY do first = first + 1 end
        for i, row in ipairs(rows) do
            local index = first + i - 1
            local alert = latest[index]
            local entry = layout[index]
            local y = entry and entry.y or 0
            local top = y - scroll.scrollY
            -- Let the scroll viewport clip partially visible rows at either edge.
            local hidden = not alert or top >= height or top + (entry and entry.height or 0) - 4 <= 0
            row.background.hidden, row.accent.hidden = hidden, hidden
            local boxHeight = entry and entry.height - 4 or 32
            row.background:SetPos(5, y); row.background:SetSize(math.max(1, scroll.contentWidth - 10), boxHeight)
            row.accent:SetPos(5, y); row.accent:SetSize(4, boxHeight)
            if not hidden then
                while #row.labels < #entry.lines do addLabel(row) end
            end
            for lineIndex, label in ipairs(row.labels) do
                label.hidden = hidden or not entry.lines[lineIndex]
                label:SetPos(17, y + (lineIndex - 1) * 18)
                label:SetSize(math.max(1, scroll.contentWidth - 27), entry and #entry.lines == 1 and 32 or 18)
                label.content = entry and entry.lines[lineIndex] or ""
            end
            if alert then row.background.colour, row.accent.colour = popup.colours(alert.level, rules) end
        end
    end
    refresh = render
    render(true)
end

function ribbon.update()
    if refresh and not pcall(refresh) then ribbon.close() end
end

function ribbon.close()
    refresh = nil
    if destroy then pcall(destroy); destroy = nil end
end

return ribbon
